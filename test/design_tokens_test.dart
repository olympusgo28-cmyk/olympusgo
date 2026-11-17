import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/theme/og_colors.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (max(x, y) + 0.05) / (min(x, y) + 0.05);
}

double max(double a, double b) => a > b ? a : b;
double min(double a, double b) => a < b ? a : b;

void main() {
  const l = OgColors.light;
  const d = OgColors.dark;

  test('P0-06 the brand colours are the ones in the checklist', () {
    expect(l.primary, const Color(0xFFE8590C));
    expect(l.text, const Color(0xFF1C1F23));
    expect(l.primarySmall, const Color(0xFFC94A00));
    expect(l.link, const Color(0xFFA83B00));
  });

  test('P0-06 there is no lime in the light theme', () {
    final colours = [
      l.primary,
      l.primaryPressed,
      l.primarySmall,
      l.primaryTint,
      l.accent,
      l.bg,
      l.surface,
      l.surfaceRaised,
      l.border,
      l.borderControl,
      l.text,
      l.textMuted,
      l.link,
      l.highlight,
      l.onInverseCardMuted,
    ];
    expect(colours, isNot(contains(OgColors.lime400)));
    expect(colours, isNot(contains(const Color(0xFFC6FF00))));
  });

  group('contrast', () {
    test('small text on the small-text fill passes 4.5:1', () {
      expect(_contrast(l.onPrimary, l.primarySmall), greaterThanOrEqualTo(4.5));
      expect(_contrast(d.onPrimary, d.primarySmall), greaterThanOrEqualTo(4.5));
    });

    test('white on the main orange is for large text only', () {
      expect(_contrast(l.onPrimary, l.primary), greaterThanOrEqualTo(3));
      expect(_contrast(l.onPrimary, l.primary), lessThan(4.5));
    });

    test('text and links pass 4.5:1 in both themes', () {
      for (final t in [l, d]) {
        expect(_contrast(t.text, t.bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(t.textMuted, t.bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(t.link, t.bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('control edges pass 3:1 in both themes', () {
      for (final t in [l, d]) {
        expect(_contrast(t.borderControl, t.bg), greaterThanOrEqualTo(3));
      }
    });
  });
}
