import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_layout.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/settings_list.dart';
import '../../guardian/application/guardian_providers.dart';
import '../../guardian/application/route_access.dart';
import '../../guardian/domain/guardian_models.dart';
import '../../play/application/play_providers.dart';
import '../../shop/application/shop_providers.dart';
import '../../social/application/social_providers.dart';
import '../application/settings_providers.dart';

/// Settings and activity, opened from the menu button on Profile: every
/// account, payment, family, privacy and support page in one searchable
/// list (owner, 9 Nov 2026). It holds what was Profile's Account list and
/// what was in the Account Centre (Q265).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(mySocialProvider).value;
    final upcoming = ref.watch(myScheduleProvider).value?.length ?? 0;
    final shop = ref.watch(myShopProvider).value;
    final info = ref.watch(privateInfoProvider).value;
    final children = (ref.watch(myChildrenProvider).value ?? const [])
        .where((l) => l.status == LinkStatus.approved)
        .length;
    final visibility = ref.watch(privacySettingsProvider).value?.visibility;
    final can = routeAccess(ref);

    String? count(int n) => n == 0 ? null : '$n';
    void open(String route) => context.push(route);

    // What the Account Centre held that nothing here did has moved in; its
    // duplicates went with it (owner, 9 Nov 2026, Q265). Sport rows live on
    // the Sport Passport, lessons in the schedule, clubs on Home. Rows for
    // screens behind Face ID show nothing of what those screens hold.
    final sections = [
      SettingsSection(
        label: 'Your account',
        helper: 'Manage your account settings.',
        helperLink: 'Learn more',
        onHelperLink: () => open(Routes.help),
        rows: [
          if (can(Routes.editProfile))
            SettingsRow(
              icon: OgIcons.person,
              label: 'Edit profile',
              onTap: () => open(Routes.editProfile),
            ),
          if (can(Routes.accountInfo))
            SettingsRow(
              icon: OgIcons.idCard,
              label: 'Account information',
              onTap: () => open(Routes.accountInfo),
            ),
          if (can(Routes.connections(followers: true)))
            SettingsRow(
              icon: OgIcons.people,
              label: 'Followers and following',
              value: social == null
                  ? null
                  : '${social.followers} · ${social.following}',
              semanticValue: social == null
                  ? null
                  : '${social.followers} followers, '
                        '${social.following} following',
              onTap: () => open(Routes.connections(followers: true)),
            ),
          if (can(Routes.identityCheck))
            SettingsRow(
              icon: OgIcons.shieldTick,
              label: 'Identity check',
              subtitle: 'Needed to run tournaments and receive payouts',
              onTap: () => open(Routes.identityCheck),
            ),
        ],
      ),
      SettingsSection(
        label: 'How you use OlympusGO',
        rows: [
          if (can(Routes.saved))
            SettingsRow(
              icon: OgIcons.bookmark,
              label: 'Saved',
              onTap: () => open(Routes.saved),
            ),
          if (can(Routes.schedule()))
            SettingsRow(
              icon: OgIcons.calendar,
              label: 'Bookings',
              value: count(upcoming),
              onTap: () => open(Routes.schedule()),
            ),
          if (can(Routes.notifications))
            SettingsRow(
              icon: OgIcons.bell,
              label: 'Notifications',
              onTap: () => open(Routes.notifications),
            ),
          if (can(Routes.timeManagement))
            SettingsRow(
              icon: OgIcons.clockFace,
              label: 'Time management',
              onTap: () => open(Routes.timeManagement),
            ),
          if (can(Routes.language))
            SettingsRow(
              icon: OgIcons.chatLines,
              label: 'Language',
              value: 'English',
              onTap: () => open(Routes.language),
            ),
          if (can(Routes.country))
            SettingsRow(
              icon: OgIcons.location,
              label: 'Country',
              value: info?.country.name,
              onTap: () => open(Routes.country),
            ),
        ],
      ),
      SettingsSection(
        label: 'Payments and orders',
        rows: [
          if (can(Routes.paymentMethods))
            SettingsRow(
              icon: OgIcons.walletCard,
              label: 'Payment methods',
              onTap: () => open(Routes.paymentMethods),
            ),
          if (can(Routes.earnings))
            SettingsRow(
              icon: OgIcons.wallet,
              label: 'Earnings and receipts',
              onTap: () => open(Routes.earnings),
            ),
          if (can(Routes.orders()))
            SettingsRow(
              icon: OgIcons.bag,
              label: 'My orders',
              onTap: () => open(Routes.orders()),
            ),
          if (shop != null)
            if (can(Routes.ownerOrders))
              SettingsRow(
                icon: OgIcons.cart,
                label: 'My shop',
                value: shop.name,
                onTap: () => open(Routes.ownerOrders),
              ),
        ],
      ),
      SettingsSection(
        label: 'Family',
        rows: [
          SettingsRow(
            icon: OgIcons.shieldPlain,
            label: 'Guardian controls',
            value: children == 0 ? null : '$children linked',
            onTap: () => open(Routes.children),
          ),
          if (can(Routes.under18))
            SettingsRow(
              icon: OgIcons.shield,
              label: 'Under-18 protection',
              subtitle: 'Settings that stay on for children',
              onTap: () => open(Routes.under18),
            ),
        ],
      ),
      SettingsSection(
        label: 'Who can see your content',
        rows: [
          if (can(Routes.privacy))
            SettingsRow(
              icon: OgIcons.padlock,
              label: 'Account privacy',
              value: visibility?.label,
              onTap: () => open(Routes.privacy),
            ),
          if (can(Routes.blocked))
            SettingsRow(
              icon: OgIcons.block,
              label: 'Blocked accounts',
              onTap: () => open(Routes.blocked),
            ),
        ],
      ),
      SettingsSection(
        label: 'Support',
        rows: [
          if (can(Routes.help))
            SettingsRow(
              icon: OgIcons.help,
              label: 'Help',
              onTap: () => open(Routes.help),
            ),
          if (can(Routes.myReports))
            SettingsRow(
              icon: OgIcons.flag,
              label: 'My reports',
              subtitle: 'Status and result of what you reported',
              onTap: () => open(Routes.myReports),
            ),
          if (can(Routes.legal))
            SettingsRow(
              icon: OgIcons.info,
              label: 'About',
              subtitle: 'Terms and privacy',
              onTap: () => open(Routes.legal),
            ),
        ],
      ),
      SettingsSection(
        rows: [
          if (can(Routes.logOut))
            SettingsRow(
              icon: OgIcons.logOut,
              label: 'Log out',
              onTap: () => open(Routes.logOut),
            ),
          if (can(Routes.deleteAccount))
            SettingsRow(
              icon: OgIcons.trash,
              label: 'Delete account',
              onTap: () => open(Routes.deleteAccount),
            ),
        ],
      ),
    ];

    return KitScaffold(
      header: KitHeader(
        title: 'Settings and activity',
        background: context.og.groupedBg,
      ),
      background: context.og.groupedBg,
      padding: const EdgeInsets.only(bottom: OgSpace.s8),
      gap: 0,
      children: [
        ReadableWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(OgSpace.s4),
                child: SettingsSearchBar(
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
              SettingsList(sections: sections, query: _query),
            ],
          ),
        ),
      ],
    );
  }
}

/// A page whose feature isn't built yet, so its Settings row has somewhere
/// to go.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => KitScaffold(
    header: KitHeader(title: title),
    children: [
      Text(
        "This isn't ready yet. It's coming in a later update.",
        style: context.type.secondary,
      ),
    ],
  );
}
