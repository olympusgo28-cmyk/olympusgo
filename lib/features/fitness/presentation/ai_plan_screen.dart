import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/fitness_providers.dart';
import '../data/fitness_repository.dart';
import '../domain/fitness_models.dart';
import 'fitness_screens.dart';

/// Asks once what AI plans send and where, then makes a plan.
class AiPlanScreen extends ConsumerStatefulWidget {
  const AiPlanScreen({super.key});

  @override
  ConsumerState<AiPlanScreen> createState() => _AiPlanScreenState();
}

class _AiPlanScreenState extends ConsumerState<AiPlanScreen> {
  var _goal = aiGoals.first.$1;
  var _days = 3;
  var _busy = false;
  String? _error;

  Future<void> _agree() async {
    // Outlives this screen, so a late answer still lands.
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      await container.read(fitnessRepositoryProvider).setAiConsent(true);
      container.invalidate(aiStatusProvider);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _make() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final request = container.read(aiPlanRequestProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    var ticket =
        container.read(aiPlanRequestProvider) ??
        AiPlanTicket(key: newFitnessId(), goal: _goal, days: _days);
    request.start(ticket);
    try {
      if (ticket.programId == null) {
        final id = await container
            .read(fitnessRepositoryProvider)
            .askPlan(key: ticket.key, goal: ticket.goal, days: ticket.days);
        ticket = ticket.saved(id);
        request.saved(ticket.key, id);
        container.invalidate(aiStatusProvider);
      }
      // The builder reads this list once, so it has to hold the new program.
      final _ = await container.refresh(workoutProgramsProvider.future);
      // If the player left, the ticket stays and the next tap opens this plan.
      if (mounted) {
        request.clear(ticket.key);
        context.pushReplacement(Routes.fitnessProgram(ticket.programId!));
      }
    } on AiPlanRefused catch (e) {
      request.clear(ticket.key);
      container.invalidate(aiStatusProvider);
      if (mounted) setState(() => _error = e.message);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn’t open your plan. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _consent() {
    return KitScaffold(
      header: const KitHeader(title: 'AI plans'),
      bottom: [
        KitButton(label: 'Agree', loading: _busy, onPressed: _agree),
        KitButton(
          label: 'Not now',
          style: KitButtonStyle.outline,
          onPressed: () => context.pop(),
        ),
      ],
      children: const [
        KitTitle(
          'Before your first plan',
          lead:
              'To write your plan, we send a summary of your workouts to '
              'Anthropic, our AI provider. It may be processed outside '
              'Singapore.',
        ),
        KitBlock(
          title: 'What we send',
          child: KitCheckList([
            'Your goal and days a week',
            'Your last 4 weeks: how often you trained, and your sets, reps '
                'and weights for each exercise',
          ]),
        ),
        KitBlock(
          title: 'What we never send',
          child: KitCheckList([
            'Your name, username, email or mobile',
            'Your birthday or age',
            'Anything you typed, like program names',
          ], crossed: true),
        ),
        KitNote(
          'AI plans are optional. You can change your mind any time in '
          'Privacy and safety.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(aiStatusProvider);
    final blocked = fitnessWaiting(
      v,
      'AI plans',
      () => ref.invalidate(aiStatusProvider),
    );
    if (blocked != null) return blocked;
    final s = v.requireValue;
    if (!s.open) {
      return const KitScaffold(
        header: KitHeader(title: 'AI plans'),
        children: [KitNote('AI plans aren’t available right now.')],
      );
    }
    if (!s.agreed) return _consent();
    // A plan under way keeps its goal and days, whatever is tapped.
    final pending = ref.watch(aiPlanRequestProvider);
    final goal = pending?.goal ?? _goal;
    final days = pending?.days ?? _days;
    final locked = _busy || pending != null;
    final ready = pending?.programId != null;
    return KitScaffold(
      header: const KitHeader(title: 'Plan with AI'),
      bottom: [
        if (_error != null) KitNote(_error!, tone: KitTone.warn),
        KitButton(
          label: ready ? 'Open my plan' : 'Make my plan',
          loading: _busy,
          onPressed: s.left > 0 || pending != null ? _make : null,
        ),
      ],
      children: [
        const KitSection('Your goal'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (key, label) in aiGoals)
              KitChip(
                label: label,
                height: 44,
                selected: key == goal,
                onTap: locked ? () {} : () => setState(() => _goal = key),
              ),
          ],
        ),
        const KitSection('Days a week'),
        Wrap(
          spacing: 8,
          children: [
            for (var n = 2; n <= 5; n++)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44),
                child: KitChip(
                  label: '$n',
                  height: 44,
                  selected: n == days,
                  onTap: locked ? () {} : () => setState(() => _days = n),
                ),
              ),
          ],
        ),
        if (_busy)
          Row(
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Writing your plan. This can take a minute.',
                  style: context.type.secondary,
                ),
              ),
            ],
          )
        else
          Text(
            ready
                ? 'Your plan is ready.'
                : pending != null
                ? 'Your plan didn’t reach you yet. Try again to get it.'
                : s.left > 0
                ? '${plural(s.left, 'plan')} left today.'
                : 'You’ve made today’s plans. Try again tomorrow.',
            style: context.type.secondary,
          ),
        const KitNote(
          'You’ll get a draft to edit. AI suggests it, so it isn’t advice from '
          'a coach or a doctor. You choose the weights.',
        ),
      ],
    );
  }
}
