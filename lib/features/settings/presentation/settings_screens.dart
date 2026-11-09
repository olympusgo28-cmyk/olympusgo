import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/resend_timer.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/code_copy.dart';
import '../../fitness/application/fitness_providers.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../../social/application/social_providers.dart';
import '../application/settings_providers.dart';
import '../domain/settings_models.dart';

enum ImageSourceChoice { camera, library }

/// Notification switches; changes save as you go.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs =
        ref.watch(notificationSettingsProvider).value ??
        const NotificationPrefs();
    final notifier = ref.read(notificationSettingsProvider.notifier);
    Future<void> change(
      NotificationPrefs Function(NotificationPrefs) edit,
    ) async {
      try {
        await notifier.change(edit);
      } on AuthFailure catch (e) {
        if (context.mounted) showOgToast(context, e.message, error: true);
      }
    }

    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Notifications',
          topGap: 8,
          lead: 'Sign-in codes and receipts always come through.',
        ),
        RowGroup(
          top: 16,
          dividers: true,
          children: [
            SwitchRow(
              title: 'Meet reminders',
              subtitle: 'Before a Meet you joined starts',
              value: prefs.meetReminders,
              onChanged: (v) => change((p) => p.copyWith(meetReminders: v)),
            ),
            SwitchRow(
              title: 'Court calls',
              subtitle: 'When it is your turn to play',
              value: prefs.courtCalls,
              onChanged: (v) => change((p) => p.copyWith(courtCalls: v)),
            ),
            SwitchRow(
              title: 'Messages',
              subtitle: 'From players and Meet hosts',
              value: prefs.messages,
              onChanged: (v) => change((p) => p.copyWith(messages: v)),
            ),
            SwitchRow(
              title: 'New followers',
              subtitle: 'When someone follows you',
              value: prefs.newFollowers,
              onChanged: (v) => change((p) => p.copyWith(newFollowers: v)),
            ),
            SwitchRow(
              title: 'Offers and news',
              subtitle: 'Tips and new features',
              value: prefs.offersAndNews,
              onChanged: (v) => change((p) => p.copyWith(offersAndNews: v)),
            ),
          ],
        ),
      ],
      bottom: [
        Text(
          'Changes save as you go.',
          textAlign: TextAlign.center,
          style: context.type.secondary,
        ),
      ],
    );
  }
}

/// Profile visibility and privacy switches; changes save as you go.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs =
        ref.watch(privacySettingsProvider).value ?? const PrivacyPrefs();
    final notifier = ref.read(privacySettingsProvider.notifier);
    final aiStatus = ref.watch(aiStatusProvider);
    final ai = aiStatus.value;
    Future<void> change(PrivacyPrefs Function(PrivacyPrefs) edit) async {
      try {
        await notifier.change(edit);
      } on AuthFailure catch (e) {
        if (context.mounted) showOgToast(context, e.message, error: true);
      }
    }

    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(title: 'Privacy and safety', topGap: 8),
        const SizedBox(height: 20),
        Text('Who can see my profile', style: context.type.caption),
        const SizedBox(height: 8),
        OgSelectField(
          value: prefs.visibility.label,
          semanticLabel: 'Who can see my profile',
          onTap: () async {
            final picked = await showOgListPicker<ProfileVisibility>(
              context: context,
              title: 'Who can see my profile',
              items: ProfileVisibility.values,
              selected: prefs.visibility,
              label: (v) => v.label,
            );
            if (picked != null) change((p) => p.copyWith(visibility: picked));
          },
        ),
        RowGroup(
          top: 20,
          dividers: true,
          children: [
            SwitchRow(
              title: 'Show my level',
              subtitle: 'Players see your Passport level',
              value: prefs.showLevel,
              onChanged: (v) => change((p) => p.copyWith(showLevel: v)),
            ),
            SwitchRow(
              title: 'Find me by mobile number',
              subtitle: 'Friends can look you up',
              value: prefs.findableByPhone,
              onChanged: (v) => change((p) => p.copyWith(findableByPhone: v)),
            ),
            SwitchRow(
              title: 'Share my location at Meets',
              subtitle: 'Only while you are checked in',
              value: prefs.shareLocationAtMeets,
              onChanged: (v) =>
                  change((p) => p.copyWith(shareLocationAtMeets: v)),
            ),
            // Stays while they've agreed, so withdrawing is always possible.
            if ((ai?.open ?? false) || (ai?.agreed ?? false))
              SwitchRow(
                title: 'AI plans',
                subtitle: 'Sends a workout summary to our AI provider',
                value: ai!.agreed,
                onChanged: (v) async {
                  if (v) {
                    await context.push(Routes.fitnessAiPlan);
                    return;
                  }
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  try {
                    await container
                        .read(fitnessRepositoryProvider)
                        .setAiConsent(false);
                    container.invalidate(aiStatusProvider);
                  } on AuthFailure catch (e) {
                    if (context.mounted) {
                      showOgToast(context, e.message, error: true);
                    }
                  }
                },
              ),
          ],
        ),
        // Never hide a way to withdraw in silence.
        if (aiStatus.hasError && !aiStatus.hasValue) ...[
          const SizedBox(height: 12),
          KitLink(
            'Can’t load AI plans. Try again',
            onPressed: () => ref.invalidate(aiStatusProvider),
          ),
        ],
      ],
      bottom: [
        Text(
          'Changes save as you go.',
          textAlign: TextAlign.center,
          style: context.type.secondary,
        ),
      ],
    );
  }
}

class BlockedPlayersScreen extends ConsumerWidget {
  const BlockedPlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedPlayersProvider);
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Blocked players',
          topGap: 8,
          lead: 'Blocked players cannot see your profile, message you or join your Meets.',
        ),
        const SizedBox(height: 12),
        ...switch (blocked) {
          AsyncData(:final value) when value.isEmpty => [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "You haven't blocked anyone.",
                style: context.type.secondary,
              ),
            ),
          ],
          AsyncData(:final value) => [
            for (final p in value)
              ListRow(
                leading: Avatar(
                  initials: p.initials,
                  tone: AvatarTone.forId(p.id),
                  imageUrl: p.avatarUrl,
                ),
                title: p.displayName,
                subtitle: p.handle,
                trailing: OgButton.outline(
                  label: 'Unblock',
                  height: 40,
                  expand: false,
                  onPressed: () async {
                    try {
                      await ref
                          .read(blockedPlayersProvider.notifier)
                          .unblock(p.id);
                      if (context.mounted) {
                        showOgToast(context, '${p.displayName} is unblocked');
                      }
                    } on AuthFailure catch (e) {
                      if (context.mounted) {
                        showOgToast(context, e.message, error: true);
                      }
                    }
                  },
                ),
              ),
          ],
          AsyncError() => [
            const OgErrorText("Can't load blocked players. Try again."),
          ],
          _ => [
            const Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(),
            ),
          ],
        },
      ],
    );
  }
}

/// Common questions and a way to reach support.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  static const _faqs = [
    (
      'How do I join a Meet?',
      'Open a Meet from Home or Discover, then tap Join. If it is full you can join the waitlist.',
    ),
    (
      'How do I change my skill level?',
      'Go to Profile, open Player profile, and edit your sport. Levels run from 1.0 to 8.0.',
    ),
    (
      'Where is my refund?',
      'Refunds go back to the card or PayNow you paid with. PayNow takes minutes, and a card takes 3 to 5 working days.',
    ),
    (
      'How do I block or report someone?',
      'Open their profile, tap the three dots, then choose Report or block.',
    ),
  ];

  String _query = '';
  final _open = <int>{};

  Future<void> _contact() async {
    final controller = TextEditingController();
    final sent = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => _SupportSheet(controller: controller),
    );
    final message = controller.text.trim();
    controller.dispose();
    if (sent != true || message.isEmpty || !mounted) return;
    try {
      await ref.read(socialRepositoryProvider).contactSupport(message);
      if (mounted) showOgToast(context, "Sent. We'll reply by email.");
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final q = _query.toLowerCase();
    final shown = [
      for (var i = 0; i < _faqs.length; i++)
        if (q.isEmpty ||
            _faqs[i].$1.toLowerCase().contains(q) ||
            _faqs[i].$2.toLowerCase().contains(q))
          i,
    ];
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(title: 'Help', topGap: 8),
        const SizedBox(height: 16),
        OgSearchField(
          hint: 'Search help',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SectionLabel('Common questions', top: 22),
        for (final i in shown)
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  expanded: _open.contains(i),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(
                      () => _open.contains(i) ? _open.remove(i) : _open.add(i),
                    ),
                    child: SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(_faqs[i].$1, style: context.type.body),
                          ),
                          AnimatedRotation(
                            turns: _open.contains(i) ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: OgIcon(
                              OgIcons.chevronDown,
                              size: 20,
                              color: c.text,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: _open.contains(i)
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _faqs[i].$2,
                            style: context.type.secondary.copyWith(
                              height: 1.45,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'No answers match. Contact support below.',
              style: context.type.secondary,
            ),
          ),
        const SizedBox(height: 12),
        KitLink(
          'Read the community rules',
          onPressed: () => context.push(Routes.communityRules),
        ),
        KitLink(
          'Terms and privacy',
          onPressed: () => context.push(Routes.legal),
        ),
      ],
      bottom: [
        OgButton.outline(
          label: 'Contact support',
          height: 52,
          onPressed: _contact,
        ),
      ],
    );
  }
}

class _SupportSheet extends StatelessWidget {
  const _SupportSheet({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Contact support', style: context.type.section),
              const SizedBox(height: 12),
              OgTextArea(
                label: 'How can we help?',
                controller: controller,
                maxLength: 2000,
                minLines: 4,
                hint: 'Tell us what happened',
              ),
              const SizedBox(height: 16),
              OgButton(
                label: 'Send',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Log out?" confirmation.
class LogOutScreen extends ConsumerStatefulWidget {
  const LogOutScreen({super.key});

  @override
  ConsumerState<LogOutScreen> createState() => _LogOutScreenState();
}

class _LogOutScreenState extends ConsumerState<LogOutScreen> {
  bool _busy = false;

  Future<void> _logOut() async {
    setState(() => _busy = true);
    ref.invalidate(onboardingControllerProvider);
    await ref.read(authRepositoryProvider).signOut();
    // The router sends signed-out players to Welcome.
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return OgFlowScreen(
      asPage: true,
      children: [
        const SizedBox(height: 160),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.primaryTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: OgIcon(OgIcons.logOut, size: 34, color: c.link),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            'Log out?',
            textAlign: TextAlign.center,
            style: context.type.title,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can log back in with your email, mobile or username.',
          textAlign: TextAlign.center,
          style: context.type.secondary,
        ),
      ],
      bottom: [
        OgButton(label: 'Log out', loading: _busy, onPressed: _logOut),
        const SizedBox(height: 10),
        OgButton.outline(
          label: 'Cancel',
          height: 52,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

/// Confirms a new mobile number or email with its 6-digit code.
class VerifyPhoneChangeScreen extends ConsumerStatefulWidget {
  const VerifyPhoneChangeScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<VerifyPhoneChangeScreen> createState() =>
      _VerifyPhoneChangeScreenState();
}

class _VerifyPhoneChangeScreenState
    extends ConsumerState<VerifyPhoneChangeScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  /// This screen confirms a new email as well as a new mobile.
  bool get _isEmail => widget.phone.contains('@');

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  CodeTarget get _target => _isEmail ? CodeTarget.email : CodeTarget.mobile;

  Future<bool> _resend() async {
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isEmail) {
        await auth.startEmailChange(widget.phone);
      } else {
        await auth.startPhoneChange(widget.phone);
      }
      return true;
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
      return false;
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_code.text.length != 6) {
      return setState(() => _error = 'Enter all 6 digits of the code.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isEmail) {
        await auth.verifyEmailChange(widget.phone, _code.text);
      } else {
        await auth.verifyPhoneChange(widget.phone, _code.text);
      }
      ref
        ..invalidate(privateInfoProvider)
        ..invalidate(accountInfoProvider);
      if (!mounted) return;
      showOgToast(
        context,
        _isEmail ? 'Email updated' : 'Mobile number updated',
      );
      // Back to the change screen, which closes itself, so the player lands
      // on Account information (or its onboarding step) with the new value.
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(Routes.accountInfo);
      }
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
      _code.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        OgHeading(
          title: codeTitle(_target),
          lead: codeLead(_target, widget.phone),
        ),
        const SizedBox(height: 32),
        OgCodeField(
          controller: _code,
          hasError: _error != null,
          onCompleted: (_) => _verify(),
        ),
        if (_error != null) OgErrorText(_error!),
        ResendTimer(onResend: _resend),
      ],
      bottom: [OgButton(label: 'Verify', loading: _busy, onPressed: _verify)],
    );
  }
}
