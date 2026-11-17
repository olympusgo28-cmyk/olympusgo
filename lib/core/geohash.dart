/// Turns a position into a geohash. The phone sends only this, and the server
/// keeps only its first few characters.
String geohash(double lat, double lng, {int precision = 5}) {
  const alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';
  var latLo = -90.0, latHi = 90.0, lngLo = -180.0, lngHi = 180.0;
  var even = true, bit = 0, value = 0;
  final out = StringBuffer();
  while (out.length < precision) {
    if (even) {
      final mid = (lngLo + lngHi) / 2;
      if (lng >= mid) {
        value = (value << 1) | 1;
        lngLo = mid;
      } else {
        value <<= 1;
        lngHi = mid;
      }
    } else {
      final mid = (latLo + latHi) / 2;
      if (lat >= mid) {
        value = (value << 1) | 1;
        latLo = mid;
      } else {
        value <<= 1;
        latHi = mid;
      }
    }
    even = !even;
    if (++bit == 5) {
      out.write(alphabet[value]);
      bit = 0;
      value = 0;
    }
  }
  return out.toString();
}
