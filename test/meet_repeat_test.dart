import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/play/domain/activity.dart';

/// A repeating Meet makes one date per picked weekday, from the first date.
void main() {
  // Thursday 1 October 2026, 8 PM.
  final draft = ActivityDraft(date: DateTime(2026, 10, 1), hour: 20, minute: 0);

  test('once is one date', () {
    expect(draft.occurrences, [DateTime(2026, 10, 1, 20)]);
    expect(draft.recurrenceLabel, isNull);
  });

  test('weekly on Tue and Fri starts from the first date', () {
    final d = draft.copyWith(
      repeat: Repeat.weekly,
      repeatDays: [5, 2],
      repeatCount: 4,
    );
    expect(d.occurrences, [
      DateTime(2026, 10, 2, 20),
      DateTime(2026, 10, 6, 20),
      DateTime(2026, 10, 9, 20),
      DateTime(2026, 10, 13, 20),
    ]);
    expect(d.recurrenceLabel, 'Every Tue and Fri');
  });

  test('every 2 weeks skips a week', () {
    final d = draft.copyWith(
      repeat: Repeat.biweekly,
      repeatDays: [4],
      repeatCount: 3,
    );
    expect(d.occurrences, [
      DateTime(2026, 10, 1, 20),
      DateTime(2026, 10, 15, 20),
      DateTime(2026, 10, 29, 20),
    ]);
    expect(d.recurrenceLabel, 'Every other Thu');
  });
}
