import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../application/fitness_providers.dart';
import '../domain/fitness_models.dart';
import '../domain/muscle_regions.dart';
import 'body_map_paths.dart';

/// The MIT notices for the body outline, as its licences ask. Registered
/// with the app's licences; the app has no page that shows them yet (Q277 g).
const bodyMapLicence = '''
Body outline path data, from MuscleMap and react-native-body-highlighter

MIT License

Copyright (c) 2026 Melih Colpan
Copyright (c) 2022 ELABBASSI Hicham

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';

/// Adds the outline's notices to the app's licences. Called once at start.
void registerBodyMapLicence() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks([
      'MuscleMap',
      'react-native-body-highlighter',
    ], bodyMapLicence);
  });
}

/// "#RRGGBB" and the opacity, for an SVG fill.
String _fill(Color c) {
  final argb = c.toARGB32();
  final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  final alpha = ((argb >> 24) & 0xFF) / 255;
  return 'fill="#$rgb" fill-opacity="${alpha.toStringAsFixed(3)}"';
}

/// The pictures already built, by view, worked parts and colours. Building
/// one joins about 25 KB of text, and screens rebuild often.
final _built = <String, String>{};

/// One view of the outline as an SVG document, with [worked] parts in
/// [on] and the rest in [off]. Kept once built.
String _cached({
  required String view,
  required Map<String, List<String>> paths,
  required String viewBox,
  required Set<String> worked,
  required Color on,
  required Color off,
}) {
  final parts = worked.toList()..sort();
  final key = '$view|${parts.join(',')}|${on.toARGB32()}|${off.toARGB32()}';
  final hit = _built[key];
  if (hit != null) return hit;
  // A handful of exercises and two themes: a small cap is plenty.
  if (_built.length >= 48) _built.remove(_built.keys.first);
  return _built[key] = bodySvg(
    paths: paths,
    viewBox: viewBox,
    worked: worked,
    on: on,
    off: off,
  );
}

/// One view of the outline as an SVG document, with [worked] parts in
/// [on] and the rest in [off].
@visibleForTesting
String bodySvg({
  required Map<String, List<String>> paths,
  required String viewBox,
  required Set<String> worked,
  required Color on,
  required Color off,
}) {
  final b = StringBuffer(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox">',
  );
  // The rest first, so a worked part is never drawn under its neighbour.
  for (final pass in [false, true]) {
    for (final e in paths.entries) {
      if (worked.contains(e.key) != pass) continue;
      final fill = _fill(pass ? on : off);
      for (final d in e.value) {
        b.write('<path d="$d" $fill/>');
      }
    }
  }
  b.write('</svg>');
  return b.toString();
}

/// The body, front and back, with the parts [muscles] work filled in the
/// brand colour. It is a picture only: screen readers skip it, so the muscle
/// names must be on screen or in a label beside it.
class BodyMap extends StatelessWidget {
  const BodyMap({
    super.key,
    required this.muscles,
    this.height = 160,
    this.onDark = false,
  });

  /// Muscle names as the catalogue writes them ("Quads", "Lower back").
  final Iterable<String> muscles;
  final double height;

  /// On the dark workout card.
  final bool onDark;

  // The artwork's own shape: 727 wide by 1,280 high.
  static const _aspect = 727 / 1280;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final on = c.primary;
    // Opaque, so shapes that touch show no darker seam. On the dark card the
    // rest is a step lighter than the card; on a page it is the border grey.
    final off = onDark
        ? Color.alphaBlend(
            c.onInverseCard.withValues(alpha: 0.22),
            c.inverseCard,
          )
        : c.border;
    final width = height * _aspect;
    Widget view(
      String name,
      Map<String, List<String>> paths,
      String box,
      Set<String> worked,
    ) => SvgPicture.string(
      _cached(
        view: name,
        paths: paths,
        viewBox: box,
        worked: worked,
        on: on,
        off: off,
      ),
      width: width,
      height: height,
    );
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          view('front', bodyFrontPaths, bodyFrontViewBox, frontParts(muscles)),
          SizedBox(width: height * 0.08),
          view('back', bodyBackPaths, bodyBackViewBox, backParts(muscles)),
        ],
      ),
    );
  }
}

/// The muscles a list of planned exercises works: a small body map and, with
/// [names], the words beside it. Left out while the catalogue can't be read,
/// or when it knows none of the muscles.
class WorkedMuscles extends ConsumerWidget {
  const WorkedMuscles({
    super.key,
    required this.items,
    this.height = 56,
    this.onDark = false,
    this.names = true,
    this.announce = true,
  });

  final List<ProgramItem> items;
  final double height;
  final bool onDark;

  /// Shows "Works quads, glutes and core" beside the map. Without it the
  /// same words are the map's label for screen readers.
  final bool names;

  /// With no [names]: whether the map carries the words as its label. Off
  /// when the same words are already on screen ([WorkedMusclesText]).
  final bool announce;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(exercisesProvider).value;
    if (catalogue == null) return const SizedBox.shrink();
    final muscles = musclesOf(items, catalogue);
    if (muscles.isEmpty) return const SizedBox.shrink();
    final words = 'Works ${muscleList(muscles).toLowerCase()}';
    final map = BodyMap(muscles: muscles, height: height, onDark: onDark);
    if (!names) return announce ? Semantics(label: words, child: map) : map;
    return Row(
      children: [
        map,
        const SizedBox(width: 12),
        Expanded(child: Text(words, style: context.type.caption)),
      ],
    );
  }
}

/// "Works quads, glutes and core", as words, for a list of planned exercises.
/// Left out on the same terms as [WorkedMuscles].
class WorkedMusclesText extends ConsumerWidget {
  const WorkedMusclesText({super.key, required this.items, this.style});

  final List<ProgramItem> items;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(exercisesProvider).value;
    if (catalogue == null) return const SizedBox.shrink();
    final muscles = musclesOf(items, catalogue);
    if (muscles.isEmpty) return const SizedBox.shrink();
    return Text(
      'Works ${muscleList(muscles).toLowerCase()}',
      style: style ?? context.type.caption,
    );
  }
}
