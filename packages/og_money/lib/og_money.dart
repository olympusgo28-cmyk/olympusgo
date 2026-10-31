/// Money is whole minor units plus a currency, never a double.
class Money implements Comparable<Money> {
  const Money(this.minor, {this.currency = 'SGD'});

  final int minor;
  final String currency;

  Money operator +(Money other) {
    _same(other);
    return Money(minor + other.minor, currency: currency);
  }

  Money operator -(Money other) {
    _same(other);
    return Money(minor - other.minor, currency: currency);
  }

  Money operator *(int times) => Money(minor * times, currency: currency);

  void _same(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Can\'t mix $currency and ${other.currency}');
    }
  }

  /// "8.00", "86.40".
  String get decimal {
    final cents = minor.abs();
    return '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
  }

  static const _symbols = {'SGD': 'S\$', 'MYR': 'RM', 'NZD': 'NZ\$'};

  /// "S$8.00", "−S$8.00".
  @override
  String toString() =>
      '${minor < 0 ? '−' : ''}${_symbols[currency] ?? '$currency '}$decimal';

  @override
  int compareTo(Money other) {
    _same(other);
    return minor.compareTo(other.minor);
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);
}

/// The fee shown on lists, before anyone pays: 10%, minimum S$2.00, half up.
/// What is charged always comes from the server's quote.
int estimatedFeeMinor(int priceMinor) {
  if (priceMinor <= 0) return 0;
  final tenth = (priceMinor + 5) ~/ 10;
  return tenth < 200 ? 200 : tenth;
}

/// Points are held in minor units: 1 point is 10 cents. "4", "4.5".
String pointsText(int minor) {
  final whole = minor.abs() ~/ 10;
  final tenth = minor.abs() % 10;
  return '${minor < 0 ? '−' : ''}$whole${tenth == 0 ? '' : '.$tenth'}';
}

/// "12.50" or "12" as minor units, or null if it isn't an amount.
int? parseMinor(String text) {
  final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(text.trim());
  if (m == null) return null;
  final cents = (m[2] ?? '').padRight(2, '0');
  return int.parse(m[1]!) * 100 + int.parse(cents);
}
