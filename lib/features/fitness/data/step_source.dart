import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/steps.dart';

/// A step source that makes up its numbers: demo mode shows it, and tests set
/// what they need. Nothing leaves the phone.
class FakeStepSource implements StepSource {
  FakeStepSource({
    StepsAccess access = StepsAccess.allowed,
    this.grants = StepsAccess.allowed,
    Map<DateTime, int>? steps,
    this.failing = false,
    this.latency = Duration.zero,
    // ignore: prefer_initializing_formals
  }) : _access = access,
       // ignore: prefer_initializing_formals
       _steps = steps;

  /// A week or so of believable numbers, today still in progress.
  factory FakeStepSource.demo() => FakeStepSource();

  StepsAccess _access;

  /// What [request] answers.
  final StepsAccess grants;

  /// Steps by day (midnight). Null makes up a pattern.
  final Map<DateTime, int>? _steps;

  /// Every read throws, to show the error state.
  bool failing;
  final Duration latency;

  /// How many times each call was made.
  int requests = 0;
  int settingsOpened = 0;
  int reads = 0;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  int _stepsOn(DateTime day) {
    final set = _steps;
    if (set != null) return set[_day(day)] ?? 0;
    final age = _day(DateTime.now()).difference(_day(day)).inDays;
    if (age == 0) return 6420;
    const pattern = [8200, 11800, 5400, 9700, 12104, 7300, 10100];
    return pattern[age % pattern.length];
  }

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failing) throw StateError('The health store is not answering.');
  }

  @override
  Future<StepsAccess> access() async => _access;

  @override
  Future<StepsAccess> request() async {
    requests++;
    _access = grants;
    return _access;
  }

  @override
  Future<List<StepsDay>> days(DateTime from, DateTime to) async {
    reads++;
    await _wait();
    final out = <StepsDay>[];
    var d = _day(from);
    final end = _day(to);
    while (!d.isAfter(end)) {
      out.add(StepsDay(d, _stepsOn(d)));
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return out;
  }

  @override
  Future<List<int>> hours(DateTime day) async {
    await _wait();
    final total = _stepsOn(day);
    // Most steps between 7 am and 8 pm, spread by a fixed shape.
    const shape = [
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      9,
      10,
      6,
      5,
      6,
      9,
      6,
      5,
      5,
      7,
      11,
      9,
      6,
      4,
      2,
      1,
      0,
    ];
    final sum = shape.fold<int>(0, (a, b) => a + b);
    final now = DateTime.now();
    final today = _day(day) == _day(now);
    return [
      for (var h = 0; h < 24; h++)
        if (today && h > now.hour) 0 else (total * shape[h] / sum).round(),
    ];
  }

  @override
  Future<void> openSettings() async {
    settingsOpened++;
  }
}

/// Where the player's own goal is kept: on the phone.
abstract interface class StepGoalStore {
  Future<int?> read();
  Future<void> write(int goal);
}

class SecureStepGoalStore implements StepGoalStore {
  const SecureStepGoalStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'og_fitness_step_goal';
  final FlutterSecureStorage _storage;

  @override
  Future<int?> read() async =>
      int.tryParse(await _storage.read(key: _key) ?? '');

  @override
  Future<void> write(int goal) => _storage.write(key: _key, value: '$goal');
}

/// A goal held in memory, for tests.
class MemoryStepGoalStore implements StepGoalStore {
  MemoryStepGoalStore([this.goal]);

  int? goal;

  @override
  Future<int?> read() async => goal;

  @override
  Future<void> write(int goal) async => this.goal = goal;
}
