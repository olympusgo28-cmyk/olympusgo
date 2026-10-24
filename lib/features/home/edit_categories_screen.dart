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
import 'application/home_categories.dart';

/// Home's shortcuts: switch them on or off, and drag to reorder.
class EditCategoriesScreen extends ConsumerStatefulWidget {
  const EditCategoriesScreen({super.key});

  @override
  ConsumerState<EditCategoriesScreen> createState() =>
      _EditCategoriesScreenState();
}

class _EditCategoriesScreenState extends ConsumerState<EditCategoriesScreen> {
  late var _order = [...ref.read(homeCategoriesControllerProvider).order];
  late final _shown = {...ref.read(homeCategoriesControllerProvider).shown};

  void _toggle(HomeCategory h, bool on) {
    if (!on && _shown.length <= minHomeCategories) {
      showOgToast(
        context,
        'At least $minHomeCategories categories stay on.',
        error: true,
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => on ? _shown.add(h) : _shown.remove(h));
  }

  Future<void> _save() async {
    await ref.read(homeCategoriesControllerProvider.notifier).save((
      order: _order,
      shown: _shown,
    ));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return KitScaffold(
      header: const KitHeader(title: 'Edit categories'),
      bottom: [KitButton(label: 'Save', onPressed: _save)],
      children: [
        const KitTitle(
          'Your Home shortcuts',
          lead: 'Turn a category off to hide it from Home. You can still reach it from Discover.',
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
            for (final (i, h) in _order.indexed)
              Container(
                key: ValueKey(h),
                constraints: const BoxConstraints(minHeight: 64),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: Semantics(
                        label: 'Reorder ${h.label}',
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
                            h.label,
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          Text(
                            h.sub,
                            style: OgText.body(13, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _shown.contains(h),
                      activeTrackColor: c.primary,
                      inactiveTrackColor: c.borderControl,
                      onChanged: (on) => _toggle(h, on),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const KitNote(
          'Hold and drag the handle to change the order. At least 3 categories stay on.',
        ),
      ],
    );
  }
}
