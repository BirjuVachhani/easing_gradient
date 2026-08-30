import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

// Importing the implementation is deliberate: these are mathematical
// regression tests for the conversion primitives, which remain package-private.
import 'package:easing_gradient/src/color_space.dart';

void main() {
  group('sRGB transfer function', () {
    test('round-trips representative and boundary values', () {
      const values = <double>[-0.2, 0, 0.0031308, 0.04045, 0.18, 0.5, 1, 1.2];
      for (final value in values) {
        expect(
          delinearizeChannel(linearizeChannel(value)),
          closeTo(value, value == 0.04045 ? 3e-8 : 1e-12),
          reason: 'Transfer functions must be inverses at $value.',
        );
      }
    });
  });

  group('OKLab', () {
    test('matches published reference values', () {
      final references = <(Color, (double, double, double))>[
        (const Color(0xFFFFFFFF), (1.000, 0.000, 0.000)),
        (const Color(0xFFFF0000), (0.628, 0.225, 0.126)),
        (const Color(0xFF00FF00), (0.866, -0.234, 0.180)),
        (const Color(0xFF0000FF), (0.452, -0.032, -0.312)),
      ];
      for (final (color, reference) in references) {
        final c = encodeColor(color, EasingColorSpace.oklab);
        expect(c.x, closeTo(reference.$1, 1e-3));
        expect(c.y, closeTo(reference.$2, 1e-3));
        expect(c.z, closeTo(reference.$3, 1e-3));
      }
    });

    test('round-trips a grid of sRGB colors', () {
      for (final r in <double>[0, 0.1, 0.5, 1]) {
        for (final g in <double>[0, 0.2, 0.7, 1]) {
          for (final b in <double>[0, 0.3, 0.9, 1]) {
            final original = Color.from(alpha: 0.73, red: r, green: g, blue: b);
            final components = encodeColor(original, EasingColorSpace.oklab);
            final decoded = decodeColor(components, EasingColorSpace.oklab);
            expect(decoded.r, closeTo(r, 2e-6));
            expect(decoded.g, closeTo(g, 2e-6));
            expect(decoded.b, closeTo(b, 2e-6));
            expect(decoded.a, closeTo(0.73, 1e-12));
          }
        }
      }
    });

    test('OKLCH round-trips colors', () {
      const colors = <Color>[
        Color(0xFF4F46E5),
        Color(0xFFF97316),
        Color(0xFF10B981),
      ];
      for (final color in colors) {
        final result = decodeColor(
          encodeColor(color, EasingColorSpace.oklch),
          EasingColorSpace.oklch,
        );
        expect(result.r, closeTo(color.r, 2e-6));
        expect(result.g, closeTo(color.g, 2e-6));
        expect(result.b, closeTo(color.b, 2e-6));
      }
    });
  });

  group('HSL', () {
    test('round-trips colors', () {
      const colors = <Color>[
        Color(0xFF4F46E5),
        Color(0xFFF97316),
        Color(0xFF10B981),
        Color(0xFF808080),
      ];
      for (final color in colors) {
        final result = decodeColor(
          encodeColor(color, EasingColorSpace.hsl),
          EasingColorSpace.hsl,
        );
        expect(result.r, closeTo(color.r, 2e-6));
        expect(result.g, closeTo(color.g, 2e-6));
        expect(result.b, closeTo(color.b, 2e-6));
      }
    });

    test('takes the short hue path across zero degrees', () {
      final from = decodeColor((
        alpha: 1,
        x: 350 * math.pi / 180,
        y: 1,
        z: 0.5,
      ), EasingColorSpace.hsl);
      final to = decodeColor((
        alpha: 1,
        x: 10 * math.pi / 180,
        y: 1,
        z: 0.5,
      ), EasingColorSpace.hsl);
      final middle = mixColors(from, to, 0.5, EasingColorSpace.hsl);
      expect(middle.r, greaterThan(0.98));
      expect(middle.g, lessThan(0.05));
      expect(middle.b, lessThan(0.05));
    });
  });

  group('premultiplied alpha', () {
    test('white to transparent stays white while alpha falls', () {
      for (final space in EasingColorSpace.values) {
        for (final t in <double>[0.1, 0.25, 0.5, 0.75, 0.9]) {
          final color = mixColors(
            const Color(0xFFFFFFFF),
            const Color(0x00000000),
            t,
            space,
          );
          expect(color.r, closeTo(1, 1e-6), reason: '$space at $t');
          expect(color.g, closeTo(1, 1e-6), reason: '$space at $t');
          expect(color.b, closeTo(1, 1e-6), reason: '$space at $t');
          expect(color.a, closeTo(1 - t, 1e-12), reason: '$space at $t');
        }
      }
    });
  });
}
