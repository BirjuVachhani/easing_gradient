import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

// Importing the implementation is deliberate: these are mathematical
// regression tests for the conversion primitives, which remain package-private.
import 'package:easing_gradient/src/color_space.dart';

void expectChannels(
  Color actual,
  (double, double, double) expected,
  double tolerance,
) {
  expect(
    actual.r,
    closeTo(expected.$1, tolerance),
    reason: 'Red must match the independently specified channel value.',
  );
  expect(
    actual.g,
    closeTo(expected.$2, tolerance),
    reason: 'Green must match the independently specified channel value.',
  );
  expect(
    actual.b,
    closeTo(expected.$3, tolerance),
    reason: 'Blue must match the independently specified channel value.',
  );
}

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

  group('output color space', () {
    const p3Red = Color.from(
      alpha: 1,
      red: 1,
      green: 0,
      blue: 0,
      colorSpace: ColorSpace.displayP3,
    );
    const p3Green = Color.from(
      alpha: 1,
      red: 0,
      green: 1,
      blue: 0,
      colorSpace: ColorSpace.displayP3,
    );

    test('matches independent CSS D65 primary conversion fixtures', () {
      // Derived from CSS Color 4 rational XYZ matrices and signed transfer,
      // not from Color.withValues or the conversion under test.
      final p3 = mixColors(
        const Color(0xFFFF0000),
        p3Red,
        0,
        EasingColorSpace.srgb,
        outputColorSpace: ColorSpace.displayP3,
      );
      expect(
        p3.colorSpace,
        ColorSpace.displayP3,
        reason: 'The selected output must be explicitly tagged.',
      );
      expectChannels(p3, (
        0.9174875573251656,
        0.20028680774084695,
        0.13856059121111408,
      ), 1e-12);
      final extended = mixColors(
        p3Red,
        p3Red,
        0,
        EasingColorSpace.srgb,
        outputColorSpace: ColorSpace.extendedSRGB,
      );
      expect(
        extended.colorSpace,
        ColorSpace.extendedSRGB,
        reason: 'P3 primaries must remain unbounded in extended sRGB.',
      );
      expectChannels(extended, (
        1.0930663624351615,
        -0.22674197356975417,
        -0.15013458093711954,
      ), 1e-12);
      final roundTrip = mixColors(
        extended,
        extended,
        1,
        EasingColorSpace.srgb,
        outputColorSpace: ColorSpace.displayP3,
      );
      expectChannels(roundTrip, (1, 0, 0), 1e-12);
    });

    test('keeps P3 chroma through rectangular and OKLCH paths', () {
      for (final space in EasingColorSpace.values.where(
        (s) => s != EasingColorSpace.hsl,
      )) {
        for (final original in [p3Red, p3Green]) {
          final result = mixColors(
            original,
            original,
            0.5,
            space,
            outputColorSpace: ColorSpace.displayP3,
          );
          expectChannels(result, (original.r, original.g, original.b), 2e-6);
          expect(
            result.colorSpace,
            ColorSpace.displayP3,
            reason: 'Every interior sample must use the selected encoding.',
          );
        }
      }
    });

    test('normalizes mixed input encodings before interpolation', () {
      const extendedRed = Color.from(
        alpha: 1,
        red: 1.0930663624351615,
        green: -0.22674197356975417,
        blue: -0.15013458093711954,
        colorSpace: ColorSpace.extendedSRGB,
      );
      for (final space in [
        EasingColorSpace.srgb,
        EasingColorSpace.linearRgb,
        EasingColorSpace.oklab,
      ]) {
        final result = mixColors(
          p3Red,
          extendedRed,
          0.5,
          space,
          outputColorSpace: ColorSpace.displayP3,
        );
        expectChannels(result, (1, 0, 0), 2e-6);
        final reversed = mixColors(
          extendedRed,
          p3Red,
          0.5,
          space,
          outputColorSpace: ColorSpace.displayP3,
        );
        expectChannels(reversed, (result.r, result.g, result.b), 1e-12);
      }
    });

    test('retains extended negatives and overshoot but clamps alpha', () {
      const from = Color.from(
        alpha: 0.25,
        red: -0.2,
        green: 0.3,
        blue: 1.4,
        colorSpace: ColorSpace.extendedSRGB,
      );
      const to = Color.from(
        alpha: 0.75,
        red: -0.2,
        green: 0.3,
        blue: 1.4,
        colorSpace: ColorSpace.extendedSRGB,
      );
      for (final space in [
        EasingColorSpace.srgb,
        EasingColorSpace.linearRgb,
        EasingColorSpace.oklab,
        EasingColorSpace.oklch,
      ]) {
        for (final t in [-1.0, 0.0, 0.5, 1.0, 2.0]) {
          final result = mixColors(
            from,
            to,
            t,
            space,
            outputColorSpace: ColorSpace.extendedSRGB,
          );
          expectChannels(result, (-0.2, 0.3, 1.4), 2e-6);
          expect(
            result.a,
            (0.25 + 0.5 * t).clamp(0.0, 1.0),
            reason: 'Alpha must be bounded even when RGB is extended.',
          );
        }
      }
    });

    test('alpha weighting preserves visible P3 color at low alpha', () {
      for (final output in [ColorSpace.displayP3, ColorSpace.extendedSRGB]) {
        for (final space in [
          EasingColorSpace.srgb,
          EasingColorSpace.linearRgb,
          EasingColorSpace.oklab,
        ]) {
          final expected = mixColors(
            p3Red,
            p3Red,
            0,
            space,
            outputColorSpace: output,
          );
          for (final t in [0.2, 0.999]) {
            final actual = mixColors(
              p3Red,
              const Color(0x00000000),
              t,
              space,
              outputColorSpace: output,
            );
            expectChannels(actual, (expected.r, expected.g, expected.b), 2e-6);
            expect(
              actual.a,
              closeTo(1 - t, 1e-12),
              reason:
                  'Wide-gamut output must retain premultiplied-alpha mixing.',
            );
          }
          final zero = mixColors(
            p3Red.withValues(alpha: 0),
            const Color(0x00000000),
            0.5,
            space,
            outputColorSpace: output,
          );
          expect(
            [zero.a, zero.r, zero.g, zero.b].every((v) => v.isFinite),
            isTrue,
            reason: 'The near-zero-alpha fallback must not divide by zero.',
          );
        }
      }
    });

    test('HSL deliberately uses bounded sRGB working input', () {
      for (final output in [ColorSpace.displayP3, ColorSpace.extendedSRGB]) {
        final actual = mixColors(
          p3Green,
          const Color(0xFFFFFFFF),
          0.5,
          EasingColorSpace.hsl,
          outputColorSpace: output,
        );
        final bounded = mixColors(
          const Color(0xFF00FF00),
          const Color(0xFFFFFFFF),
          0.5,
          EasingColorSpace.hsl,
          outputColorSpace: output,
        );
        expectChannels(actual, (bounded.r, bounded.g, bounded.b), 1e-12);
      }
      expect(
        mixColors(
          p3Green,
          p3Red,
          0,
          EasingColorSpace.hsl,
          outputColorSpace: ColorSpace.displayP3,
        ),
        p3Green,
        reason: 'Direct endpoints bypass the HSL working-gamut limitation.',
      );
    });

    test('default and explicit sRGB retain legacy output', () {
      for (final space in EasingColorSpace.values) {
        for (final t in [0.0, 0.25, 0.5, 1.0]) {
          expect(
            mixColors(p3Red, const Color(0x800080FF), t, space),
            mixColors(
              p3Red,
              const Color(0x800080FF),
              t,
              space,
              outputColorSpace: ColorSpace.sRGB,
            ),
            reason: 'Opt-in output must not alter the default path.',
          );
        }
      }
      final bounded = decodeColor((
        alpha: 1.2,
        x: -0.3,
        y: 0.4,
        z: 1.5,
      ), EasingColorSpace.srgb);
      expectChannels(bounded, (0, 0.4, 1), 0);
      expect(
        bounded.a,
        1,
        reason: 'Default sRGB keeps its previous alpha clamp.',
      );
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
