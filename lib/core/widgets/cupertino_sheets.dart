import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/og_colors.dart';
import '../../core/theme/og_type.dart';

/// Native iOS bottom picker with a Done button, used for dates, countries
/// and levels so they feel like the system pickers.
Future<T?> showOgPickerSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(ValueSetter<T> onChanged) picker,
  required T initial,
}) {
  var value = initial;
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) {
      final c = context.og;
      return Material(
        type: MaterialType.transparency,
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      CupertinoButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: context.type.secondary),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: context.type.section,
                        ),
                      ),
                      CupertinoButton(
                        onPressed: () => Navigator.of(context).pop(value),
                        child: Text(
                          'Done',
                          style: context.type.button.copyWith(color: c.link),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: c.border),
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: Theme.of(context).brightness,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: context.type.body,
                        dateTimePickerTextStyle: context.type.body,
                      ),
                    ),
                    child: picker((v) => value = v),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// A simple list picker built on [CupertinoPicker].
Future<T?> showOgListPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required T selected,
  required String Function(T) label,
}) {
  return showOgPickerSheet<T>(
    context: context,
    title: title,
    initial: selected,
    picker: (onChanged) => CupertinoPicker(
      itemExtent: 40,
      scrollController: FixedExtentScrollController(
        initialItem: items.indexOf(selected),
      ),
      onSelectedItemChanged: (i) => onChanged(items[i]),
      children: [for (final item in items) Center(child: Text(label(item)))],
    ),
  );
}
