import '../../../../core/format.dart';
import '../../domain/activity.dart';

/// "1,284".
String thousands(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// "Thu 19 Nov, 2:37 – 10:37 AM", or a date range when it runs several days.
String playCardDateLine(Activity a) {
  if (a.kind == ActivityKind.tournament && a.multiDay) {
    return Fmt.dayRange(a.startsAt, a.endsAt);
  }
  if (a.endsAt.day != a.startsAt.day) return Fmt.dayRange(a.startsAt, a.endsAt);
  return Fmt.dayTimeRange(a.startsAt, a.endsAt);
}

/// The line under the date of a tournament or event: its own note, else its
/// repeat pattern, else when registration closes.
String? playCardDateNote(Activity a) =>
    a.subtitle ??
    a.recurrence ??
    (a.registrationClosesAt != null
        ? 'Registration closes ${Fmt.day(a.registrationClosesAt!)}'
        : null);

/// "Free", or "S$8.00 / entry" (tournaments and events).
String playCardEntryPrice(Activity a) =>
    a.isFree ? 'Free' : 'S\$${money(a.feeCents)} / entry';
