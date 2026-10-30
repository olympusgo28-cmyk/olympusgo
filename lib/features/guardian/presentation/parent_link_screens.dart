import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/guardian_providers.dart';
import '../domain/guardian_models.dart';

/// The restricted shell: everything a player under 18 can reach until a
/// parent links their account.
class RestrictedHomeScreen extends ConsumerWidget {
  const RestrictedHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final status = ref.watch(restrictionsProvider).value;
    final pending = status?.pendingParent ?? false;
    final suspended = status?.suspended ?? false;
    return KitScaffold(
      children: [
        Semantics(
          header: true,
          child: Text('OlympusGO', style: OgText.h1.copyWith(color: c.text)),
        ),
        KitNote(
          suspended
              ? 'Your account is suspended'
              : pending
              ? 'Your parent has your code. Ask them to approve the link.'
              : 'Ask a parent to link your account',
          tone: KitTone.warn,
        ),
        Text(
          suspended
              ? 'You can read our rules and contact help, but not use the rest '
                    'of OlympusGO.'
              : 'Until a parent links your account, you can set up your '
                    'profile, but not join Meets, chat, scan or shop.',
          style: OgText.lead(c.textMuted),
        ),
        if (!suspended)
          KitButton(
            label: 'Show my parent a code',
            onPressed: () => context.push(Routes.parentCode),
          ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.settings,
              title: 'Settings',
              onTap: () => context.push(Routes.settings),
            ),
            KitNavTile(
              icon: OgIcons.shield,
              title: 'Staying safe',
              onTap: () => context.push(Routes.under18),
              ruleAbove: true,
            ),
            KitNavTile(
              icon: OgIcons.help,
              title: 'Help',
              onTap: () => context.push(Routes.help),
              ruleAbove: true,
            ),
          ],
        ),
        KitButton.outline(
          label: 'Log out',
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}

/// The child shows this to a parent, who types it on their own phone.
class ParentCodeScreen extends ConsumerStatefulWidget {
  const ParentCodeScreen({super.key});

  @override
  ConsumerState<ParentCodeScreen> createState() => _ParentCodeScreenState();
}

class _ParentCodeScreenState extends ConsumerState<ParentCodeScreen> {
  late Future<ParentCode> _code = _newCode();

  Future<ParentCode> _newCode() =>
      ref.read(guardianRepositoryProvider).createCode();

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return KitScaffold(
      header: const KitHeader(title: 'Your parent code'),
      children: [
        Text(
          'Show this to your parent or guardian. They open OlympusGO on their '
          'phone and enter it under Profile, then My children.',
          style: OgText.lead(c.textMuted),
        ),
        FutureBuilder(
          future: _code,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return KitNote(
                snapshot.error is AuthFailure
                    ? (snapshot.error! as AuthFailure).message
                    : 'Something went wrong. Try again.',
                tone: KitTone.warn,
              );
            }
            final code = snapshot.data;
            return KitCard(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: code == null
                      ? const CircularProgressIndicator()
                      : Semantics(
                          label:
                              'Your code is ${code.code.split('').join(' ')}',
                          child: ExcludeSemantics(
                            child: SelectableText(
                              code.code,
                              style: OgText.heading(36, color: c.text),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'It works for 24 hours, and only once.',
                    style: OgText.body(14, color: c.textMuted),
                  ),
                ),
              ],
            );
          },
        ),
        KitButton.outline(
          label: 'Get a new code',
          onPressed: () => setState(() => _code = _newCode()),
        ),
      ],
    );
  }
}

/// A parent types their child's code, then approves or says no.
class EnterChildCodeScreen extends ConsumerStatefulWidget {
  const EnterChildCodeScreen({super.key});

  @override
  ConsumerState<EnterChildCodeScreen> createState() =>
      _EnterChildCodeScreenState();
}

class _EnterChildCodeScreenState extends ConsumerState<EnterChildCodeScreen> {
  final _code = TextEditingController();
  PendingLink? _pending;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await action();
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeem() => _run(() async {
    final link = await ref
        .read(guardianRepositoryProvider)
        .redeemCode(_code.text.trim());
    HapticFeedback.mediumImpact();
    setState(() => _pending = link);
  });

  Future<void> _decide(bool approve) => _run(() async {
    await ref
        .read(guardianRepositoryProvider)
        .decide(_pending!.linkId, approve: approve);
    ref.invalidate(myChildrenProvider);
    if (!mounted) return;
    showOgToast(context, approve ? 'Account linked' : 'Link declined');
    context.go(Routes.children);
  });

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final pending = _pending;
    if (pending != null) {
      return KitScaffold(
        header: const KitHeader(title: 'Link this account?'),
        children: [
          Text(
            "You're linking ${pending.childName}'s account to yours. You can see "
            'and delete what they post, and end the link at any time.',
            style: OgText.lead(c.textMuted),
          ),
          if (_error != null) KitNote(_error!, tone: KitTone.warn),
          KitButton(
            label: 'Approve',
            loading: _busy,
            onPressed: () => _decide(true),
          ),
          KitButton.outline(
            label: 'Not my child',
            onPressed: () => _decide(false),
          ),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Link a child'),
      children: [
        Text(
          "Enter the 8-character code from your child's phone.",
          style: OgText.lead(c.textMuted),
        ),
        KitInput(
          label: 'Code',
          controller: _code,
          hint: 'ABCD2345',
          maxLength: 8,
        ),
        if (_error != null) KitNote(_error!, tone: KitTone.warn),
        KitButton(label: 'Continue', loading: _busy, onPressed: _redeem),
      ],
    );
  }
}

/// The accounts a parent has linked.
class MyChildrenScreen extends ConsumerWidget {
  const MyChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final children = ref.watch(myChildrenProvider);
    return KitScaffold(
      header: const KitHeader(title: 'My children'),
      children: [
        ...children.when(
          loading: () => const [Center(child: CircularProgressIndicator())],
          error: (e, _) => [
            KitNote(
              "Can't load this right now. Pull down to try again.",
              tone: KitTone.warn,
            ),
          ],
          data: (list) => list.isEmpty
              ? [
                  Text(
                    "No linked accounts yet. Ask your child for their code.",
                    style: OgText.lead(c.textMuted),
                  ),
                ]
              : [
                  KitCard(
                    children: [
                      for (final (i, child) in list.indexed)
                        KitNavTile(
                          icon: OgIcons.person,
                          title: child.name,
                          subtitle: child.status == LinkStatus.approved
                              ? 'Linked'
                              : 'Waiting for your approval',
                          ruleAbove: i > 0,
                          onTap: () => context.push(
                            Routes.child(child.childId!),
                            extra: child,
                          ),
                        ),
                    ],
                  ),
                ],
        ),
        KitButton(
          label: 'Link a child',
          onPressed: () => context.push(Routes.enterChildCode),
        ),
      ],
    );
  }
}

/// One child: what they posted, and ending the link.
class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.childId, this.link});

  final String childId;
  final GuardianLink? link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final posts = ref.watch(childPostsProvider(childId));
    final groups =
        ref.watch(childGroupRequestsProvider(childId)).value ?? const [];

    Future<void> decide(GroupRequest group, bool approve) async {
      try {
        await ref
            .read(guardianRepositoryProvider)
            .decideGroup(childId, group, approve: approve);
        ref.invalidate(childGroupRequestsProvider(childId));
      } on AuthFailure catch (e) {
        if (context.mounted) showOgToast(context, e.message, error: true);
      }
    }

    return KitScaffold(
      header: KitHeader(title: link?.name ?? 'Your child'),
      children: [
        if (groups.isNotEmpty) const KitSection('Groups waiting for you'),
        for (final group in groups)
          KitCard(
            padding: const EdgeInsets.all(16),
            children: [
              Text(group.name, style: OgText.body(16, color: c.text)),
              if (group.area.isNotEmpty)
                Text(group.area, style: OgText.body(13, color: c.textMuted)),
              const SizedBox(height: 8),
              KitButton(
                label: 'Approve',
                height: 44,
                onPressed: () => decide(group, true),
              ),
              const SizedBox(height: 8),
              KitButton.outline(
                label: 'Not this one',
                height: 44,
                onPressed: () => decide(group, false),
              ),
            ],
          ),
        const KitSection('What they posted'),
        ...posts.when(
          loading: () => const [Center(child: CircularProgressIndicator())],
          error: (e, _) => [
            KitNote(
              e is AuthFailure ? e.message : "Can't load this right now.",
              tone: KitTone.warn,
            ),
          ],
          data: (list) => list.isEmpty
              ? [
                  Text(
                    'Nothing posted yet.',
                    style: OgText.body(16, color: c.textMuted),
                  ),
                ]
              : [
                  for (final post in list)
                    KitCard(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          post.kindLabel,
                          style: OgText.body(13, color: c.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(post.body, style: OgText.body(16, color: c.text)),
                        const SizedBox(height: 8),
                        KitButton.outline(
                          label: 'Delete',
                          height: 44,
                          onPressed: () async {
                            try {
                              await ref
                                  .read(guardianRepositoryProvider)
                                  .deletePost(childId, post);
                              ref.invalidate(childPostsProvider(childId));
                            } on AuthFailure catch (e) {
                              if (context.mounted) {
                                showOgToast(context, e.message, error: true);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                ],
        ),
        if (link != null)
          KitButton.outline(
            label: 'End this link',
            onPressed: () async {
              try {
                await ref.read(guardianRepositoryProvider).revoke(link!.linkId);
                ref.invalidate(myChildrenProvider);
                if (context.mounted) context.pop();
              } on AuthFailure catch (e) {
                if (context.mounted) {
                  showOgToast(context, e.message, error: true);
                }
              }
            },
          ),
      ],
    );
  }
}
