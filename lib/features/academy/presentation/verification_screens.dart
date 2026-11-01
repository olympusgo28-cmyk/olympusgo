import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/academy_providers.dart';

/// A photo of a document, as bytes. Never saved on the phone.
Future<Uint8List?> _pickDocument() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 2000,
  );
  return file?.readAsBytes();
}

Widget? _waiting(AsyncValue<Object?> v, String title, VoidCallback retry) {
  if (v.hasValue) return null;
  return KitScaffold(
    header: KitHeader(title: title),
    children: v.hasError
        ? [
            KitNote(
              v.error is AuthFailure
                  ? (v.error! as AuthFailure).message
                  : 'Can’t load this right now. Check your connection.',
              tone: KitTone.warn,
            ),
            KitButton(label: 'Try again', onPressed: retry),
          ]
        : const [CupertinoActivityIndicator()],
  );
}

String _licenceLabel(String status) => switch (status) {
  'verified' => 'Verified',
  'submitted' => 'In review',
  'rejected' => 'Needs another look',
  _ => 'Not sent',
};

/// The owner's checklist, and sending the business details for review.
class AcademyVerifyScreen extends ConsumerStatefulWidget {
  const AcademyVerifyScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AcademyVerifyScreen> createState() =>
      _AcademyVerifyScreenState();
}

class _AcademyVerifyScreenState extends ConsumerState<AcademyVerifyScreen> {
  final _uen = TextEditingController();
  Uint8List? _file;
  bool _busy = false;

  @override
  void dispose() {
    _uen.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final bytes = await _pickDocument();
    if (bytes != null && mounted) setState(() => _file = bytes);
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final repo = ref.read(coachRepositoryProvider);
    try {
      final path = await repo.uploadDocument(_file!, 'image/jpeg');
      await repo.submitBusiness(widget.id, uen: _uen.text, path: path);
      HapticFeedback.mediumImpact();
      ref.invalidate(academyChecklistProvider(widget.id));
      ref.invalidate(academyProvider(widget.id));
      if (mounted) {
        setState(() => _file = null);
        showOgToast(context, 'Sent for review');
      }
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(academyChecklistProvider(widget.id));
    final blocked = _waiting(
      v,
      'Verification',
      () => ref.invalidate(academyChecklistProvider(widget.id)),
    );
    if (blocked != null) return blocked;
    final a = v.requireValue;
    final canSend =
        a.isOwner && (a.verification == 'none' || a.verification == 'rejected');
    return KitScaffold(
      header: const KitHeader(title: 'Verification'),
      bottom: canSend
          ? [
              KitButton(
                label: 'Send for review',
                loading: _busy,
                onPressed: _file == null ? null : _send,
              ),
            ]
          : null,
      children: [
        KitTitle(
          switch (a.verification) {
            'verified' => 'You’re verified',
            'submitted' => 'We’re reviewing this',
            _ => 'Get verified',
          },
          size: 28,
          lead:
              'The academy needs a business licence. Everyone who coaches '
              'needs an NROC licence. We review within 1 – 3 working days. '
              'Parents can’t find you until you’re verified, and you can set '
              'up classes while you wait.',
        ),
        if (a.verification == 'rejected' && a.rejectedReason != null)
          KitNote(a.rejectedReason!, tone: KitTone.warn),
        KitKeyValue('Business licence', a.uen ?? 'Not sent'),
        KitNavTile(
          icon: OgIcons.shieldTick,
          title: 'Payout account',
          subtitle: a.payoutReady ? 'Verified' : 'Not verified yet',
          onTap: a.isOwner ? () => context.push(Routes.payoutAccount) : null,
          chevron: a.isOwner,
        ),
        for (final k in a.coaches)
          KitNavTile(
            icon: OgIcons.people,
            title: k.name,
            subtitle: k.accepted
                ? 'NROC licence: ${_licenceLabel(k.licence)}'
                : 'Hasn’t answered yet',
            onTap: k.head ? () => context.push(Routes.coachMe) : null,
            chevron: k.head,
          ),
        if (canSend) ...[
          KitInput(
            label: 'UEN',
            controller: _uen,
            hint: '201912345A',
            maxLength: 10,
          ),
          KitButton.outline(
            label: _file == null
                ? 'Add a photo of your business licence'
                : 'Change the photo',
            onPressed: _pick,
          ),
        ],
        const KitNote(
          'Documents are seen only by our review team, and we delete them '
          'after the check. Parents see the Verified badge, never the '
          'documents.',
        ),
      ],
    );
  }
}

/// A coach's licence, and the details on their public page.
class CoachMeScreen extends ConsumerStatefulWidget {
  const CoachMeScreen({super.key});

  @override
  ConsumerState<CoachMeScreen> createState() => _CoachMeScreenState();
}

class _CoachMeScreenState extends ConsumerState<CoachMeScreen> {
  final _number = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _years = TextEditingController();
  DateTime? _expires;
  Uint8List? _file;
  bool _busy = false;
  bool _filled = false;

  @override
  void dispose() {
    for (final c in [_number, _headline, _bio, _years]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final bytes = await _pickDocument();
    if (bytes != null && mounted) setState(() => _file = bytes);
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final start = _expires ?? now.add(const Duration(days: 365));
    final picked = await showOgPickerSheet<DateTime>(
      context: context,
      title: 'Licence expires',
      initial: start,
      picker: (onChanged) => CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: start,
        minimumDate: now,
        onDateTimeChanged: onChanged,
      ),
    );
    if (picked != null) setState(() => _expires = picked);
  }

  Future<void> _act(Future<void> Function() run, String done) async {
    setState(() => _busy = true);
    try {
      await run();
      HapticFeedback.mediumImpact();
      ref.invalidate(myLicenceProvider);
      if (mounted) showOgToast(context, done);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendLicence() => _act(() async {
    final repo = ref.read(coachRepositoryProvider);
    final path = await repo.uploadDocument(_file!, 'image/jpeg');
    await repo.submitLicence(
      number: _number.text,
      expires: _expires!,
      path: path,
    );
    if (mounted) setState(() => _file = null);
  }, 'Sent for review');

  Future<void> _saveProfile() => _act(
    () => ref
        .read(coachRepositoryProvider)
        .saveProfile(
          headline: _headline.text,
          bio: _bio.text,
          years: int.tryParse(_years.text.trim()),
        ),
    'Saved',
  );

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(myLicenceProvider);
    final blocked = _waiting(
      v,
      'Coaching',
      () => ref.invalidate(myLicenceProvider),
    );
    if (blocked != null) return blocked;
    final l = v.requireValue;
    if (!_filled) {
      _filled = true;
      _headline.text = l.headline;
      _bio.text = l.bio;
      _years.text = l.yearsCoaching?.toString() ?? '';
      _number.text = l.number ?? '';
      _expires = l.expiresOn;
    }
    return KitScaffold(
      header: const KitHeader(title: 'Coaching'),
      children: [
        KitKeyValue('NROC licence', _licenceLabel(l.status)),
        if (l.status == 'rejected' && l.rejectedReason != null)
          KitNote(l.rejectedReason!, tone: KitTone.warn),
        KitInput(label: 'NROC number', controller: _number, maxLength: 30),
        KitNavTile(
          icon: OgIcons.calendar,
          title: 'Expires',
          subtitle: _expires == null ? 'Pick a date' : Fmt.day(_expires!),
          onTap: _pickExpiry,
        ),
        KitButton.outline(
          label: _file == null
              ? 'Add a photo of your licence'
              : 'Change the photo',
          onPressed: _pick,
        ),
        KitButton(
          label: 'Send licence for review',
          loading: _busy,
          onPressed: _file == null || _expires == null ? null : _sendLicence,
        ),
        KitInput(label: 'Headline', controller: _headline, maxLength: 80),
        KitTextArea(label: 'About you', controller: _bio),
        KitInput(
          label: 'Years coaching',
          controller: _years,
          keyboardType: TextInputType.number,
        ),
        KitButton.outline(
          label: 'Save my page',
          onPressed: _busy ? null : _saveProfile,
        ),
      ],
    );
  }
}

/// An academy has asked this person to coach. Nothing happens until they agree.
class CoachInviteScreen extends ConsumerStatefulWidget {
  const CoachInviteScreen({super.key, required this.academyId});

  final String academyId;

  @override
  ConsumerState<CoachInviteScreen> createState() => _CoachInviteScreenState();
}

class _CoachInviteScreenState extends ConsumerState<CoachInviteScreen> {
  bool _busy = false;

  Future<void> _answer(bool accept) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(coachRepositoryProvider)
          .answerInvite(widget.academyId, accept: accept);
      ref.invalidate(coachInvitesProvider);
      ref.invalidate(academyListProvider);
      if (!mounted) return;
      if (accept) {
        context.pushReplacement(Routes.academyToday(widget.academyId));
      } else {
        kitPop(context);
      }
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(coachInvitesProvider);
    final blocked = _waiting(
      v,
      'Coaching invitation',
      () => ref.invalidate(coachInvitesProvider),
    );
    if (blocked != null) return blocked;
    final name = v.requireValue
        .where((x) => x.$1 == widget.academyId)
        .map((x) => x.$2)
        .firstOrNull;
    if (name == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Coaching invitation'),
        children: [KitNote('This invitation has ended.')],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Coaching invitation'),
      bottom: [
        KitButton(
          label: 'Yes, I coach here',
          loading: _busy,
          onPressed: () => _answer(true),
        ),
        KitButton.outline(
          label: 'No thanks',
          onPressed: _busy ? null : () => _answer(false),
        ),
      ],
      children: [
        KitTitle(
          'Coach at $name?',
          size: 28,
          lead:
              'You’ll see your classes once we’ve verified your NROC licence.',
        ),
      ],
    );
  }
}

/// A coach's public page.
class CoachPageScreen extends ConsumerWidget {
  const CoachPageScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final v = ref.watch(coachProfileProvider(id));
    final blocked = _waiting(
      v,
      'Coach',
      () => ref.invalidate(coachProfileProvider(id)),
    );
    if (blocked != null) return blocked;
    final p = v.requireValue;
    return KitScaffold(
      header: const KitHeader(title: 'Coach'),
      children: [
        KitTitle(
          p.name,
          size: 28,
          lead: p.headline.isEmpty ? null : p.headline,
        ),
        KitTag(
          'NROC licence verified',
          background: context.tones.successFill,
          foreground: context.tones.onSuccessFill,
        ),
        if (p.yearsCoaching != null)
          KitKeyValue('Coaching for', plural(p.yearsCoaching!, 'year')),
        if (p.bio.isNotEmpty)
          Text(p.bio, style: OgText.body(15, height: 1.45, color: c.textMuted)),
        for (final (academy, name, role) in p.academies)
          KitNavTile(
            icon: OgIcons.mortarboard,
            title: name,
            subtitle: role,
            onTap: () => context.push(Routes.academy(academy)),
          ),
      ],
    );
  }
}
