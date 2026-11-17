// The muscle body map (owner, 17 Nov 2026): which parts of the outline each
// muscle lights up, and the map on an exercise, a program day and My workouts.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/fitness/data/fitness_repository.dart';
import 'package:olympus_go/features/fitness/domain/fitness_models.dart';
import 'package:olympus_go/features/fitness/domain/muscle_regions.dart';
import 'package:olympus_go/features/fitness/presentation/body_map.dart';
import 'package:olympus_go/features/fitness/presentation/body_map_paths.dart';
import 'package:olympus_go/features/fitness/presentation/fitness_screens.dart';
import 'package:olympus_go/features/fitness/presentation/program_screens.dart';

CatalogExercise _exercise(String id, List<String> muscles) => CatalogExercise(
  id: id,
  name: id,
  mark: 'XX',
  group: 'legs',
  equipment: 'Bodyweight',
  muscles: muscles,
);

ProgramItem _item(String id) =>
    ProgramItem(exerciseId: id, exercise: id, mark: 'XX', sets: 3, reps: 10);

/// The demo template a new program can start from.
const _template = 'Court speed';

class _NoCatalogue extends DemoFitnessRepository {
  @override
  Future<List<CatalogExercise>> exercises() async =>
      throw StateError('no signal');
}

void main() {
  group('muscles and the outline', () {
    test('every muscle in the catalogue has a place on the map', () {
      // The seed is the catalogue: '{Quads,Glutes,Core}' on each exercise.
      final sql = File(
        'supabase/migrations/20261108100000_fitness_catalogue.sql',
      ).readAsStringSync();
      final names = <String>{
        for (final m in RegExp(r"'\{([A-Za-z, ]+)\}', '[A-Z]").allMatches(sql))
          ...m.group(1)!.split(',').map((s) => s.trim()),
      };
      // Every exercise row was read: one muscle list per row.
      final rows = RegExp(r"^  \('", multiLine: true).allMatches(sql).length;
      final lists = RegExp(r"'\{([A-Za-z, ]+)\}', '[A-Z]").allMatches(sql);
      expect(rows, 40);
      expect(lists.length, rows);
      expect(names.length, 14);
      expect(names.where((n) => knownMuscles([n]).isEmpty), isEmpty);
      // And the map knows no muscle the catalogue never uses.
      expect(muscleRegions.keys.toSet(), names);
    });

    test('every place named exists in the outline', () {
      for (final e in muscleRegions.entries) {
        expect(
          e.value.front.where((p) => !bodyFrontPaths.containsKey(p)),
          isEmpty,
          reason: '${e.key}, front',
        );
        expect(
          e.value.back.where((p) => !bodyBackPaths.containsKey(p)),
          isEmpty,
          reason: '${e.key}, back',
        );
        expect(e.value.front.length + e.value.back.length, greaterThan(0));
      }
    });

    test('the outline has both views, with no empty part', () {
      expect(bodyFrontPaths.keys, containsAll(['chest', 'abs', 'quadriceps']));
      expect(bodyBackPaths.keys, containsAll(['gluteal', 'hamstring']));
      for (final paths in [bodyFrontPaths, bodyBackPaths]) {
        for (final e in paths.entries) {
          expect(e.value, isNotEmpty, reason: e.key);
          expect(e.value.every((d) => d.startsWith('M')), isTrue);
        }
      }
    });

    test('front and back parts for a set of muscles', () {
      expect(frontParts(['Quads', 'Core']), {'quadriceps', 'abs'});
      expect(backParts(['Quads', 'Core']), isEmpty);
      expect(backParts(['Glutes', 'Back']), {
        'gluteal',
        'upper-back',
        'rhomboids',
        'trapezius',
      });
      expect(frontParts(['Shoulders']), {'deltoids'});
      expect(backParts(['Shoulders']), {'deltoids'});
    });

    test('names match whatever their case, and unknown ones are left out', () {
      expect(frontParts(['quads', ' CORE ']), {'quadriceps', 'abs'});
      expect(frontParts(['Jaw']), isEmpty);
      expect(knownMuscles(['Quads', 'Jaw', 'quads', 'Core']), [
        'Quads',
        'Core',
      ]);
    });

    test('a day’s muscles, the most-used first', () {
      final catalogue = [
        _exercise('squat', ['Quads', 'Glutes', 'Core']),
        _exercise('lunge', ['Quads', 'Glutes']),
        _exercise('plank', ['Core']),
        _exercise('curl', ['Biceps']),
      ];
      final muscles = musclesOf([
        _item('curl'),
        _item('squat'),
        _item('lunge'),
        _item('gone'),
      ], catalogue);
      // Quads and Glutes twice each, then Biceps and Core once, as first met.
      expect(muscles, ['Quads', 'Glutes', 'Biceps', 'Core']);
      expect(musclesOf(const [], catalogue), isEmpty);
      expect(musclesOf([_item('gone')], catalogue), isEmpty);
    });

    test('the names as one phrase', () {
      expect(muscleList(const []), '');
      expect(muscleList(['Quads']), 'Quads');
      expect(muscleList(['Quads', 'Glutes']), 'Quads and glutes');
      expect(
        muscleList(['Quads', 'Lower back', 'Core']),
        'Quads, lower back and core',
      );
    });
  });

  group('the picture', () {
    const on = Color(0xFFFF5722);
    const off = Color(0x33000000);

    test('worked parts take the brand colour, the rest stay pale', () {
      final svg = bodySvg(
        paths: bodyFrontPaths,
        viewBox: bodyFrontViewBox,
        worked: {'quadriceps'},
        on: on,
        off: off,
      );
      expect(
        svg,
        startsWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox'),
      );
      expect(svg, contains('viewBox="0 95 727 1280"'));
      final total = bodyFrontPaths.values.fold<int>(0, (a, p) => a + p.length);
      expect('<path '.allMatches(svg).length, total);
      expect(
        'fill="#ff5722" fill-opacity="1.000"'.allMatches(svg).length,
        bodyFrontPaths['quadriceps']!.length,
      );
      expect(
        'fill="#000000" fill-opacity="0.200"'.allMatches(svg).length,
        total - bodyFrontPaths['quadriceps']!.length,
      );
    });

    test('nothing worked is all pale', () {
      final svg = bodySvg(
        paths: bodyBackPaths,
        viewBox: bodyBackViewBox,
        worked: const {},
        on: on,
        off: off,
      );
      expect(svg, isNot(contains('#ff5722')));
      expect(svg, contains('viewBox="718 95 727 1280"'));
    });

    test('worked parts are drawn last, on top', () {
      final svg = bodySvg(
        paths: bodyFrontPaths,
        viewBox: bodyFrontViewBox,
        worked: {'chest'},
        on: on,
        off: off,
      );
      expect(svg.indexOf('#ff5722'), greaterThan(svg.lastIndexOf('#000000')));
    });
  });

  group('on screen', () {
    Future<void> pump(
      WidgetTester tester,
      Widget child, {
      FitnessRepository? repo,
    }) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fitnessRepositoryProvider.overrideWithValue(
              repo ?? DemoFitnessRepository(),
            ),
          ],
          retry: (_, _) => null,
          child: MaterialApp(
            theme: OgTheme.light(),
            home: Scaffold(body: Center(child: child)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the map draws a front and a back', (tester) async {
      await pump(tester, const BodyMap(muscles: ['Quads', 'Glutes']));
      expect(find.byType(SvgPicture), findsNWidgets(2));
      final size = tester.getSize(find.byType(SvgPicture).first);
      expect(size.height, 160);
      expect(size.width, closeTo(160 * 727 / 1280, 0.01));
    });

    testWidgets('the map is a picture only: screen readers skip it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const BodyMap(muscles: ['Quads']));
      expect(
        find.ancestor(
          of: find.byType(SvgPicture).first,
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      handle.dispose();
    });

    testWidgets('a day’s map names the muscles beside it', (tester) async {
      await pump(
        tester,
        WorkedMuscles(items: [_item('squat'), _item('push-up')]),
      );
      expect(find.byType(BodyMap), findsOne);
      expect(
        find.text('Works quads, glutes, core, chest, shoulders and triceps'),
        findsOne,
      );
    });

    testWidgets('without the words, the map carries them as its label', (
      tester,
    ) async {
      await pump(tester, WorkedMuscles(items: [_item('lunge')], names: false));
      expect(find.text('Works quads and glutes'), findsNothing);
      expect(find.bySemanticsLabel('Works quads and glutes'), findsOne);
    });

    testWidgets('it is left out when the catalogue can’t be read', (
      tester,
    ) async {
      await pump(
        tester,
        WorkedMuscles(items: [_item('squat')]),
        repo: _NoCatalogue(),
      );
      expect(find.byType(BodyMap), findsNothing);
      expect(find.textContaining('Works'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    });

    testWidgets('it is left out when no exercise is known', (tester) async {
      await pump(tester, WorkedMuscles(items: [_item('not-in-the-list')]));
      expect(find.byType(BodyMap), findsNothing);
    });

    Future<void> open(
      WidgetTester tester,
      String at, {
      Size size = const Size(390, 1600),
      double scale = 1,
      bool dark = false,
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(path: '/host', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: Routes.fitness,
            builder: (_, _) => const FitnessHomeScreen(),
          ),
          GoRoute(
            path: '/fitness/exercises/:id',
            builder: (_, s) =>
                ExerciseDetailScreen(id: s.pathParameters['id']!),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fitnessRepositoryProvider.overrideWithValue(
              DemoFitnessRepository(),
            ),
          ],
          retry: (_, _) => null,
          child: MaterialApp.router(
            theme: dark ? OgTheme.dark() : OgTheme.light(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      router.push(at);
      await tester.pumpAndSettle();
    }

    testWidgets('an exercise shows where its muscles are', (tester) async {
      await open(tester, Routes.fitnessExercise('squat'));
      expect(find.byType(BodyMap), findsOne);
      final map = tester.widget<BodyMap>(find.byType(BodyMap));
      expect(map.muscles, ['Quads', 'Glutes', 'Core']);
      // The names stay as tags, so the picture is never the only carrier.
      expect(find.text('Quads'), findsOne);
      expect(find.text('Glutes'), findsOne);
    });

    testWidgets('My workouts shows the muscles the next workout works', (
      tester,
    ) async {
      await open(tester, Routes.fitness);
      expect(find.text('Start workout'), findsOne);
      final worked = tester.widget<WorkedMuscles>(find.byType(WorkedMuscles));
      expect(worked.onDark, isTrue);
      // The words are on the card, so the picture is not the only carrier
      // and is not read out a second time.
      expect(find.textContaining(RegExp(r'^Works ')), findsOne);
      expect(worked.names, isFalse);
      expect(worked.announce, isFalse);
      expect(find.bySemanticsLabel(RegExp(r'^Works ')), findsOne);
    });

    testWidgets('on a narrow phone with large text the card keeps the words '
        'and drops the picture', (tester) async {
      await open(tester, Routes.fitness, size: const Size(320, 1600), scale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Start workout'), findsOne);
      expect(find.textContaining(RegExp(r'^Works ')), findsOne);
      expect(find.byType(WorkedMuscles), findsNothing);
    });

    testWidgets('on a narrow phone at normal text the card fits', (
      tester,
    ) async {
      await open(tester, Routes.fitness, size: const Size(320, 1600));
      expect(tester.takeException(), isNull);
      expect(find.byType(WorkedMuscles), findsOne);
    });

    testWidgets('the exercise page fits a narrow phone with large text, in '
        'the dark theme', (tester) async {
      await open(
        tester,
        Routes.fitnessExercise('squat'),
        size: const Size(320, 2400),
        scale: 2,
        dark: true,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(BodyMap), findsOne);
    });

    testWidgets('a program day shows its muscles once it has exercises', (
      tester,
    ) async {
      await pump(tester, const ProgramBuilderScreen(id: 'new'));
      expect(find.byType(WorkedMuscles), findsNothing);
      await tester.ensureVisible(find.text(_template));
      await tester.tap(find.text(_template));
      await tester.pumpAndSettle();
      expect(find.byType(WorkedMuscles), findsOne);
      expect(find.textContaining(RegExp(r'^Works ')), findsOne);
    });

    testWidgets('makes no claim about recovery, balance or health', (
      tester,
    ) async {
      final banned = RegExp(
        r'recover|neglect|untrained|overtrain|balance|sore|fatigue|calor|'
        r'point|badge|streak|rank|\bshould\b|\bmust\b|healthy|injur',
        caseSensitive: false,
      );
      String words() => [
        ...tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? ''),
        ...tester
            .widgetList<Semantics>(find.byType(Semantics))
            .map((s) => s.properties.label ?? ''),
      ].join(' | ');

      // The words this change adds: beside the map, and as its label.
      await pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WorkedMuscles(items: [_item('squat'), _item('push-up')]),
            WorkedMuscles(items: [_item('lunge')], names: false),
            WorkedMusclesText(items: [_item('plank')]),
          ],
        ),
      );
      final added = words();
      expect(added, contains('Works quads and glutes'));
      expect(added, contains('Works core'));
      expect(banned.hasMatch(added), isFalse, reason: added);
      // Every muscle name the map can say.
      expect(banned.hasMatch(muscleRegions.keys.join(' ')), isFalse);
    });
  });

  group('the licence', () {
    // Both projects whose artwork this is, and the permission notice itself,
    // not just a pointer to it.
    const copyrights = [
      'Copyright (c) 2026 Melih Colpan',
      'Copyright (c) 2022 ELABBASSI Hicham',
    ];
    const permission = [
      'Permission is hereby granted, free of charge',
      'The above copyright notice and this permission notice shall be',
      'THE SOFTWARE IS PROVIDED "AS IS"',
    ];
    String flat(String s) => s.replaceAll(RegExp(r'\s*\n(// ?)?\s*'), ' ');

    test('both MIT notices are in the app’s licences', () async {
      registerBodyMapLicence();
      final entries = await LicenseRegistry.licenses.toList();
      final ours = entries.where((e) => e.packages.contains('MuscleMap'));
      expect(ours, isNotEmpty);
      expect(ours.first.packages, contains('react-native-body-highlighter'));
      final text = flat(ours.first.paragraphs.map((p) => p.text).join('\n'));
      for (final line in [...copyrights, ...permission]) {
        expect(text, contains(line));
      }
    });

    test('the app registers them when it starts', () {
      final main = File('lib/main.dart').readAsStringSync();
      final body = main.substring(main.indexOf('Future<void> main()'));
      expect(body, contains('registerBodyMapLicence();'));
      expect(
        body.indexOf('registerBodyMapLicence();'),
        lessThan(body.indexOf('runApp(')),
      );
    });

    test('the notice is also in the repository', () {
      final notice = flat(File('NOTICE.md').readAsStringSync());
      final paths = flat(
        File('lib/features/fitness/presentation/body_map_paths.dart')
            .readAsStringSync(),
      );
      for (final text in [notice, paths]) {
        for (final line in [...copyrights, ...permission]) {
          expect(text, contains(line));
        }
        // Where it came from, pinned.
        expect(text, contains('d53ddf4d480b65979f1008b203e6b6eda0e67e54'));
      }
    });
  });
}
