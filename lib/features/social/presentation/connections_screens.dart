import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/share.dart';
import '../../auth/data/auth_repository.dart';
import '../../shell/tab_page.dart';
import '../application/social_providers.dart';
import '../domain/social_models.dart';

/// Following and Followers, switched with the pill tabs.
class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key, this.followers = false});

  final bool followers;

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  late int _tab = widget.followers ? 1 : 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final me = ref.watch(currentUserIdProvider).value ?? '';
    final social = ref.watch(mySocialProvider).value ?? const PlayerSocial();
    final mine = ref.watch(myFollowingProvider).value ?? const {};
    final list = _tab == 0
        ? ref.watch(followingOfProvider(me))
        : ref.watch(followersOfProvider(me));
    final q = _query.toLowerCase();

    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const SizedBox(height: 12),
        PillTabs(
          labels: [
            'Following ${social.following}',
            'Followers ${social.followers}',
          ],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        OgSearchField(
          hint: 'Search',
          height: 48,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        ...switch (list) {
          AsyncData(:final value) => [
            for (final p in value.where(
              (p) =>
                  q.isEmpty ||
                  p.displayName.toLowerCase().contains(q) ||
                  (p.username ?? '').contains(q),
            ))
              ListRow(
                minHeight: 68,
                onTap: () => context.push(Routes.player(p.id)),
                leading: Avatar(
                  initials: p.initials,
                  tone: AvatarTone.forId(p.id),
                  imageUrl: p.avatarUrl,
                ),
                title: p.displayName,
                subtitle: p.handle,
                trailing: FollowButton(
                  following: mine.contains(p.id),
                  followLabel: _tab == 1 ? 'Follow back' : 'Follow',
                  onPressed: () async {
                    try {
                      await ref.read(myFollowingProvider.notifier).toggle(p.id);
                    } on AuthFailure catch (e) {
                      if (context.mounted) {
                        showOgToast(context, e.message, error: true);
                      }
                    }
                  },
                ),
              ),
            if (value.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _tab == 0
                      ? 'Follow players to see their games and Passports here.'
                      : 'No followers yet. Share your profile so players can find you.',
                  style: OgText.body(16, height: 1.45, color: c.textMuted),
                ),
              ),
          ],
          AsyncError() => [
            const OgErrorText("Can't load this list. Try again."),
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

/// Share profile: preview card and copyable link.
class ShareProfileScreen extends ConsumerWidget {
  const ShareProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final profile = ref.watch(sessionProfileProvider).value;
    final username = profile?.username ?? '';
    final link = '${Links.host}/$username';
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Share profile',
          topGap: 8,
          lead:
              'Send your link so players can follow you and see your Passport.',
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Column(
            children: [
              Avatar(
                initials: profile?.initials ?? '?',
                tone: AvatarTone.brand,
                imageUrl: profile?.avatarUrl,
                size: 96,
                fontSize: 36,
              ),
              const SizedBox(height: 14),
              Text(
                profile?.fullName ?? '',
                style: OgText.display(26, color: c.text),
              ),
              const SizedBox(height: 6),
              Text('@$username', style: OgText.body(15, color: c.textMuted)),
              const SizedBox(height: 16),
              // Players scan this from their Scan tab to open your profile.
              Semantics(
                label: 'QR code for your profile',
                child: QrImageView(
                  data: 'https://$link',
                  size: 148,
                  padding: EdgeInsets.zero,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: c.text,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: c.text,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Profile link', style: OgText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                readOnly: true,
                label: 'Profile link',
                value: link,
                child: Container(
                  height: 56,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.borderControl, width: 2),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OgText.body(16, color: c.text),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: OgButton.outline(
                label: 'Copy',
                height: 56,
                fontSize: 17,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'https://$link'));
                  showOgToast(context, 'Link copied');
                },
              ),
            ),
          ],
        ),
      ],
      bottom: [OgButton(label: 'Done', onPressed: () => context.pop())],
    );
  }
}

/// Saved Meets, players and clubs. Players are live; Meets and clubs fill in
/// as those features ship.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final players = ref.watch(savedPlayersProvider);
    return TabPage(
      children: [
        const Align(alignment: Alignment.centerLeft, child: OgBackButton()),
        const OgHeading(
          title: 'Saved',
          topGap: 8,
          lead: 'Meets, players and clubs you bookmarked.',
        ),
        const SizedBox(height: 16),
        PillTabs(
          labels: const ['Meets', 'Players', 'Clubs'],
          index: _tab,
          height: 40,
          fontSize: 16,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 8),
        if (_tab == 1)
          ...switch (players) {
            AsyncData(:final value) when value.isEmpty => [
              _empty(c, 'Players you save show up here.'),
            ],
            AsyncData(:final value) => [
              for (final p in value)
                ListRow(
                  onTap: () => context.push(Routes.player(p.id)),
                  leading: Avatar(
                    initials: p.initials,
                    tone: AvatarTone.forId(p.id),
                    imageUrl: p.avatarUrl,
                  ),
                  title: p.displayName,
                  subtitle: p.handle,
                  trailing: Semantics(
                    button: true,
                    label: 'Remove from saved',
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(savedPlayersProvider.notifier).unsave(p.id),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          CupertinoIcons.bookmark_fill,
                          color: c.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            AsyncError() => [
              const OgErrorText("Can't load saved players. Try again."),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(24),
                child: CupertinoActivityIndicator(),
              ),
            ],
          }
        else
          _empty(
            c,
            _tab == 0
                ? 'Meets you save show up here.'
                : 'Clubs you save show up here.',
          ),
      ],
    );
  }

  Widget _empty(OgColors c, String text) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(text, style: OgText.body(16, height: 1.45, color: c.textMuted)),
  );
}
