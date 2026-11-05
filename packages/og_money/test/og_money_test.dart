import 'package:flutter_test/flutter_test.dart';
import 'package:og_money/og_money.dart';

void main() {
  test('prices read S\$8.00', () {
    expect('${const Money(800)}', 'S\$8.00');
    expect('${const Money(4840)}', 'S\$48.40');
    expect('${const Money(5)}', 'S\$0.05');
    expect('${const Money(-800)}', '−S\$8.00');
  });

  test('sums stay in whole cents', () {
    expect(const Money(10) + const Money(20), const Money(30));
    expect(const Money(800) - const Money(200), const Money(600));
    expect(const Money(330) * 3, const Money(990));
  });

  test('currencies never mix', () {
    expect(
      () => const Money(1) + const Money(1, currency: 'MYR'),
      throwsArgumentError,
    );
  });

  test('the list fee matches the fee table', () {
    expect(estimatedFeeMinor(600), 200);
    expect(estimatedFeeMinor(2000), 200);
    expect(estimatedFeeMinor(2005), 201);
    expect(estimatedFeeMinor(3000), 300);
    expect(estimatedFeeMinor(4400), 440);
    expect(estimatedFeeMinor(6000), 600);
    expect(estimatedFeeMinor(0), 0);
  });

  test('points are tenths of a dollar, with integer maths', () {
    expect(pointsText(400), '40');
    expect(pointsText(45), '4.5');
    expect(pointsText(0), '0');
    expect(pointsText(-30), '−3');
  });

  test('an amount typed by staff becomes cents exactly', () {
    expect(parseMinor('24.50'), 2450);
    expect(parseMinor('24.5'), 2450);
    expect(parseMinor('24'), 2400);
    expect(parseMinor('0.07'), 7);
    expect(parseMinor('19.99'), 1999);
    expect(parseMinor('12.1.5'), isNull);
    expect(parseMinor('-1'), isNull);
    expect(parseMinor(''), isNull);
    expect(parseMinor('1.999'), isNull);
  });
}
