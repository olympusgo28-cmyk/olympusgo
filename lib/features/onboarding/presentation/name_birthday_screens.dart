import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/country.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../guardian/application/guardian_providers.dart';
import '../application/onboarding_controller.dart';

/// Step 1: full name, typed large like a Passport.
class FullNameScreen extends ConsumerStatefulWidget {
  const FullNameScreen({super.key});

  @override
  ConsumerState<FullNameScreen> createState() => _FullNameScreenState();
}

class _FullNameScreenState extends ConsumerState<FullNameScreen> {
  late final _name = TextEditingController(
    text: ref.read(onboardingControllerProvider).fullName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    ref.read(onboardingControllerProvider.notifier).setName(name);
    context.push(Routes.birthday);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return OgFlowScreen(
      children: [
        OgBackButton(onPressed: () => _confirmLeave(context, ref)),
        const OgHeading(
          title: "What's your name?",
          step: 1,
          topGap: 16,
          lead: 'This is the name other players see on your Passport.',
        ),
        const SizedBox(height: 32),
        Semantics(
          label: 'Full name',
          textField: true,
          child: TextField(
            controller: _name,
            autofocus: true,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 80,
            onChanged: (_) => setState(() {}),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onSubmitted: (_) => _continue(),
            style: context.type.display.copyWith(height: 1.2),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              hintText: 'Full name',
              hintStyle: context.type.display.copyWith(
                color: c.border,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
      bottom: [
        OgButton(
          label: 'Continue',
          onPressed: _name.text.trim().isEmpty ? null : _continue,
        ),
      ],
    );
  }
}

/// Leaving onboarding signs out, so ask first.
Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
  final leave = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Stop setting up?'),
      content: const Text(
        "You'll be logged out. Log in again any time to finish.",
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep going'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );
  if (leave == true) {
    ref.invalidate(onboardingControllerProvider);
    await ref.read(authRepositoryProvider).signOut();
  }
}

/// Step 2: date of birth and country.
class BirthdayScreen extends ConsumerStatefulWidget {
  const BirthdayScreen({super.key});

  @override
  ConsumerState<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends ConsumerState<BirthdayScreen> {
  late DateTime? _date = ref.read(onboardingControllerProvider).birthday;
  late Country _country = ref.read(onboardingControllerProvider).country;
  String? _error;
  bool _busy = false;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showOgPickerSheet<DateTime>(
      context: context,
      title: 'Date of birth',
      initial: _date ?? DateTime(now.year - 20, now.month, now.day),
      picker: (onChanged) => CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: _date ?? DateTime(now.year - 20, now.month, now.day),
        minimumDate: DateTime(1900),
        maximumDate: now,
        dateOrder: DatePickerDateOrder.dmy,
        onDateTimeChanged: onChanged,
      ),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day);
        _error = null;
      });
    }
  }

  Future<void> _pickCountry() async {
    final picked = await showOgListPicker<Country>(
      context: context,
      title: 'Country',
      items: Country.values,
      selected: _country,
      label: (c) => c.name,
    );
    if (picked != null) setState(() => _country = picked);
  }

  /// The server works out the age group from the birthday and the country's
  /// limits, so the branch below follows its answer, not a sum done here.
  Future<void> _continue() async {
    final date = _date;
    if (date == null) {
      return setState(() => _error = 'Enter your date of birth.');
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final audience = await ref
          .read(guardianRepositoryProvider)
          .setBirthday(date, _country);
      ref
          .read(onboardingControllerProvider.notifier)
          .setBirthday(date, _country);
      ref.invalidate(restrictionsProvider);
      if (!mounted) return;
      context.push(audience == 'adult' ? Routes.sports : Routes.parent);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget part(
      String label,
      String value, {
      double? width,
      bool flex = false,
    }) {
      // Outlined (Q251): the label rests inside until a date is picked.
      final field = OgSelectField(
        label: label,
        value: value,
        chevron: false,
        placeholder: _date == null,
        onTap: _pickDate,
      );
      return flex
          ? Expanded(child: field)
          : SizedBox(width: width, child: field);
    }

    final d = _date;
    return OgFlowScreen(
      children: [
        const OgBackButton(),
        const OgHeading(
          title: "When's your birthday?",
          step: 2,
          topGap: 16,
          lead:
              'We use it to switch on the right protections. Only you can see it, '
              "and it can't be changed later.",
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            part('Day', d == null ? 'DD' : '${d.day}', width: 80),
            const SizedBox(width: 8),
            part(
              'Month',
              d == null ? 'Month' : _months[d.month - 1],
              flex: true,
            ),
            const SizedBox(width: 8),
            part('Year', d == null ? 'YYYY' : '${d.year}', width: 96),
          ],
        ),
        const SizedBox(height: 20),
        OgSelectField(
          label: 'Country',
          value: _country.name,
          onTap: _pickCountry,
        ),
        const SizedBox(height: 8),
        Text(
          'Sets your currency, emergency number and local rules.',
          style: context.type.secondary.copyWith(height: 1.4),
        ),
        if (_error != null) OgErrorText(_error!),
      ],
      bottom: [
        OgButton(label: 'Continue', loading: _busy, onPressed: _continue),
      ],
    );
  }
}

/// Under 18: a parent or guardian approves the account.
class ParentApprovalScreen extends StatelessWidget {
  const ParentApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OgFlowScreen(
      children: const [
        OgBackButton(),
        SizedBox(height: 24),
        OgIconBadge(
          child: OgIcon(
            OgIcons.shield,
            size: 36,
            color: OgColors.orange300,
            strokeWidth: 2.2,
          ),
        ),
        OgHeading(
          title: 'A parent needs to link your account',
          lead:
              "Because you're under 18, a parent or guardian links their OlympusGO "
              "account to yours. Finish setting up, then you'll get a code to show them.",
        ),
      ],
      bottom: [
        OgButton(
          label: 'Continue',
          onPressed: () => context.push(Routes.sports),
        ),
      ],
    );
  }
}
