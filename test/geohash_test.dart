import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/geohash.dart';

void main() {
  test('P2-01 a known point gives the known geohash', () {
    expect(geohash(57.64911, 10.40744, precision: 11), 'u4pruydqqvj');
  });

  test('P2-01 the default is coarse, about 5 km', () {
    expect(geohash(1.3521, 103.8198), hasLength(5));
  });

  test('nearby points share a cell', () {
    expect(geohash(1.3521, 103.8198), geohash(1.3525, 103.8201));
  });
}
