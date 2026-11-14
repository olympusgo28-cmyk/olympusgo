import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Material,
        MaterialType,
        ReorderableListView,
        ReorderableDragStartListener;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/og_kit.dart';
import '../../core/widgets/og_toast.dart';
import 'application/home_services.dart';

/// Pick Home's four favourites, and drag to reorder every service.
class EditFavouritesScreen extends ConsumerStatefulWidget {
  const EditFavouritesScreen({super.key});

  @override
  ConsumerState<EditFavouritesScreen> createState() =>
      _EditFavouritesScreenState();
}

class _EditFavouritesScreenState extends ConsumerState<EditFavouritesScreen> {
  late var _order = [...ref.read(homeServicesControllerProvider).order];
  late final _favourites = {
    ...ref.read(homeServicesControllerProvider).favourites,
  };

  void _toggle(HomeService s, bool on) {
    if (on && _favourites.length >= homeFavouriteCount) {
      showOgToast(
        context,
        'You have $homeFavouriteCount favourites. Turn one off first.',
        error: true,
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => on ? _favourites.add(s) : _favourites.remove(s));
  }

  Future<void> _save() async {
    await ref.read(homeServicesControllerProvider.notifier).save((
      order: _order,
      favourites: _favourites,
    ));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final missing = homeFavouriteCount - _favourites.length;
    return KitScaffold(
      header: const KitHeader(title: 'Edit favourites'),
      bottom: [
        KitButton(
          label: missing == 0 ? 'Save' : 'Pick $missing more',
          onPressed: missing == 0 ? _save : null,
        ),
      ],
      children: [
        const KitTitle(
          'Your favourites',
          lead:
              'Pick $homeFavouriteCount services to show as cards at the top of Home. The rest stay in More services.',
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, _, _) => Material(
            type: MaterialType.transparency,
            child: ColoredBox(color: c.bg, child: child),
          ),
          onReorderItem: (from, to) => setState(() {
            final next = [..._order];
            next.insert(to, next.removeAt(from));
            _order = next;
          }),
          children: [
            for (final (i, s) in _order.indexed)
              Container(
                key: ValueKey(s),
                constraints: const BoxConstraints(minHeight: 64),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: Semantics(
                        label: 'Reorder ${s.label}',
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: OgIcon(
                              OgIcons.reorder,
                              size: 22,
                              color: c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.label,
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          Text(
                            s.sub,
                            style: OgText.body(13, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: '${s.label} as a favourite',
                      child: CupertinoSwitch(
                        value: _favourites.contains(s),
                        activeTrackColor: c.primary,
                        inactiveTrackColor: c.borderControl,
                        onChanged: (on) => _toggle(s, on),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const KitNote(
          'Hold and drag the handle to change the order of your favourites and More services.',
        ),
      ],
    );
  }
}
