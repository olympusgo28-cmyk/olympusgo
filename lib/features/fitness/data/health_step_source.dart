import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/steps.dart';

/// The few things the step reader needs from the phone's health store. One
/// implementation talks to Apple Health or Health Connect; tests use a fake.
abstract interface class HealthGateway {
  /// Is there a health store to read from?
  Future<bool> available();

  /// Whether reading steps is allowed. Null when the phone will not say
  /// (Apple Health never says whether a read was refused).
  Future<bool?> canReadSteps();

  /// Shows the phone's permission sheet. True when it was answered yes, or,
  /// on iPhone, when it was shown without an error.
  Future<bool> askToReadSteps();

  /// Steps between [start] and [end], counted once across every app and
  /// device that writes them. Null when there are none.
  Future<int?> steps(DateTime start, DateTime end);

  Future<void> openSettings();
}

/// Remembers that the player has been asked, since Apple Health cannot say.
abstract interface class StepsAskedStore {
  Future<bool> read();
  Future<void> write();
}

class SecureStepsAskedStore implements StepsAskedStore {
  const SecureStepsAskedStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'og_fitness_steps_asked';
  final FlutterSecureStorage _storage;

  @override
  Future<bool> read() async => await _storage.read(key: _key) == '1';

  @override
  Future<void> write() => _storage.write(key: _key, value: '1');
}

class MemoryStepsAskedStore implements StepsAskedStore {
  MemoryStepsAskedStore([this.asked = false]);

  bool asked;

  @override
  Future<bool> read() async => asked;

  @override
  Future<void> write() async => asked = true;
}

/// Reads steps from Apple Health or Health Connect. Nothing read here is sent
/// anywhere or written to a log.
class HealthStepSource implements StepSource {
  HealthStepSource({HealthGateway? gateway, StepsAskedStore? asked})
    : _gateway = gateway ?? PluginHealthGateway(),
      _asked = asked ?? const SecureStepsAskedStore();

  final HealthGateway _gateway;
  final StepsAskedStore _asked;

  @override
  Future<StepsAccess> access() async {
    if (!await _gateway.available()) return StepsAccess.unavailable;
    final can = await _gateway.canReadSteps();
    if (can ?? false) return StepsAccess.allowed;
    // Not allowed, or the phone will not say. Once asked, iPhone (which never
    // says) is taken as allowed, since a refusal just reads as no steps;
    // Android says no for real.
    if (!await _asked.read()) return StepsAccess.notAsked;
    return can == null ? StepsAccess.allowed : StepsAccess.denied;
  }

  @override
  Future<StepsAccess> request() async {
    if (!await _gateway.available()) return StepsAccess.unavailable;
    final granted = await _gateway.askToReadSteps();
    await _asked.write();
    if (granted) return StepsAccess.allowed;
    return StepsAccess.denied;
  }

  @override
  Future<List<StepsDay>> days(DateTime from, DateTime to) async {
    final first = DateTime(from.year, from.month, from.day);
    final last = DateTime(to.year, to.month, to.day);
    final now = DateTime.now();
    final starts = <DateTime>[];
    for (
      var d = first;
      !d.isAfter(last);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      starts.add(d);
    }
    final counts = await Future.wait([
      for (final d in starts)
        _gateway.steps(d, _end(d, DateTime(d.year, d.month, d.day + 1), now)),
    ]);
    return [
      for (var i = 0; i < starts.length; i++)
        StepsDay(starts[i], _clean(counts[i])),
    ];
  }

  @override
  Future<List<int>> hours(DateTime day) async {
    final base = DateTime(day.year, day.month, day.day);
    final now = DateTime.now();
    final counts = await Future.wait([
      for (var h = 0; h < 24; h++)
        if (base.add(Duration(hours: h)).isAfter(now))
          Future<int?>.value(0)
        else
          _gateway.steps(
            DateTime(base.year, base.month, base.day, h),
            _end(
              DateTime(base.year, base.month, base.day, h),
              DateTime(base.year, base.month, base.day, h + 1),
              now,
            ),
          ),
    ]);
    return [for (final c in counts) _clean(c)];
  }

  @override
  Future<void> openSettings() => _gateway.openSettings();

  /// A period still in progress ends now.
  static DateTime _end(DateTime start, DateTime end, DateTime now) =>
      end.isAfter(now) ? now : end;

  /// No negative or missing counts.
  static int _clean(int? steps) => steps == null || steps < 0 ? 0 : steps;
}

/// The real thing: the `health` plugin on iPhone and Android.
class PluginHealthGateway implements HealthGateway {
  PluginHealthGateway([Health? health]) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _types = [HealthDataType.STEPS];
  static const _read = [HealthDataAccess.READ];

  bool get _supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<void> _ready() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> available() async {
    if (!_supported) return false;
    // Health Connect is an app on older Android phones: without it there is
    // nothing to read from.
    return _health.isHealthConnectAvailable();
  }

  @override
  Future<bool?> canReadSteps() async {
    await _ready();
    return _health.hasPermissions(_types, permissions: _read);
  }

  @override
  Future<bool> askToReadSteps() async {
    await _ready();
    return _health.requestAuthorization(_types, permissions: _read);
  }

  @override
  Future<int?> steps(DateTime start, DateTime end) async {
    await _ready();
    return _health.getTotalStepsInInterval(start, end);
  }

  @override
  Future<void> openSettings() async {
    if (Platform.isIOS) {
      // Apple Health keeps its own list, which an app cannot open directly:
      // this opens the app's page in Settings.
      await launchUrl(Uri.parse('app-settings:'));
    } else {
      // Health Connect shows its own sheet again, if Android still allows it.
      await _ready();
      await _health.requestAuthorization(_types, permissions: _read);
    }
  }
}
