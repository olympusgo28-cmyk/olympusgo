/// Date and time wording used across the app ("Fri 16 Oct · 7:30 PM").
abstract final class Fmt {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const monthsLong = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "Fri 16 Oct".
  static String day(DateTime d) =>
      '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  /// "7:30 PM".
  static String time(DateTime d) => clock(d.hour, d.minute);

  static String clock(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
  }

  /// "Fri 16 Oct · 7:30 PM".
  static String dayTime(DateTime d) => '${day(d)} · ${time(d)}';

  /// "Fri 16 Oct, 7:30 PM".
  static String dayTimeComma(DateTime d) => '${day(d)}, ${time(d)}';

  /// "8:00 – 10:00 PM", or "11:00 AM – 1:00 PM" across noon.
  static String timeRange(DateTime a, DateTime b) {
    final sameHalf = (a.hour < 12) == (b.hour < 12);
    final start = time(a);
    return '${sameHalf ? start.substring(0, start.length - 3) : start} – ${time(b)}';
  }

  /// "Sat 24 – Sun 25 Oct", or "Sat 31 Oct – Sun 1 Nov" across months.
  static String dayRange(DateTime a, DateTime b) => a.month == b.month
      ? '${_days[a.weekday - 1]} ${a.day} – ${day(b)}'
      : '${day(a)} – ${day(b)}';

  /// "Fri 2 Oct, 8:00 – 10:00 PM".
  static String dayTimeRange(DateTime a, DateTime b) =>
      '${day(a)}, ${timeRange(a, b)}';

  /// "NEXT UP · TUE 13 OCT · 7:30 PM" style eyebrow.
  static String upper(DateTime d) => dayTime(d).toUpperCase();

  /// "Sat 7 to Sun 8 Nov".
  static String range(DateTime a, DateTime b) => a.month == b.month
      ? '${_days[a.weekday - 1]} ${a.day} to ${day(b)}'
      : '${day(a)} to ${day(b)}';

  /// "2 hours", "1.5 hours".
  static String duration(int minutes) {
    final h = minutes / 60;
    final n = h == h.roundToDouble()
        ? h.toInt().toString()
        : h.toStringAsFixed(1);
    return '$n hour${h == 1 ? '' : 's'}';
  }
}

/// "1 student", "3 students".
String plural(int n, String one, [String? many]) =>
    '$n ${n == 1 ? one : (many ?? '${one}s')}';
