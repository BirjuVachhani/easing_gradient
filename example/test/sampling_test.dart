import 'dart:math' as math;
import 'dart:ui' show Color, ColorSpace;

import 'package:easing_gradient/easing_gradient.dart';
import 'package:easing_gradient_example/benchmark/sampling.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

const _from = Color(0xFF2563EB);
const _to = Color(0xFFFACC15);

void main() {
  group('sampleGradient', () {
    test('uniform is the package baseline, including transparent guards', () {
      for (final space in EasingColorSpace.values) {
        final expected = easeColorStops(
          colors: const [Color(0x00FF0000), _to],
          colorSpace: space,
        );
        final actual = sampleGradient(
          from: const Color(0x00FF0000),
          to: _to,
          curve: Curves.easeInOut,
          space: space,
        );
        expect(actual.colors, expected.colors);
        expect(actual.stops, expected.stops);
      }
    });

    test(
      'strategies preserve endpoints, order, bounds and immutable lists',
      () {
        for (final strategy in SamplingStrategy.values) {
          for (final space in EasingColorSpace.values) {
            for (final samples in [1, 2, 15, 31, 63]) {
              final result = sampleGradient(
                from: _from,
                to: _to,
                curve: Curves.easeInOut,
                space: space,
                samples: samples,
                strategy: strategy,
              );
              expect(result.stops.first, 0);
              expect(result.stops.last, 1);
              expect(result.colors.first, _from);
              expect(result.colors.last, _to);
              expect(result.colors.length, result.stops.length);
              expect(result.stops.length, lessThanOrEqualTo(samples + 2));
              expect(result.stops, orderedEquals([...result.stops]..sort()));
              expect(result.stops, everyElement(inInclusiveRange(0, 1)));
              for (final color in result.colors) {
                expect([
                  color.a,
                  color.r,
                  color.g,
                  color.b,
                ], everyElement(inInclusiveRange(0, 1)));
              }
              expect(() => result.stops.add(1), throwsUnsupportedError);
              expect(() => result.colors.add(_to), throwsUnsupportedError);
            }
          }
        }
      },
    );

    test('Bezier samples x(u) but evaluates the baseline transform at x', () {
      const curve = Cubic(0.11, 0.73, 0.39, 0.91);
      final result = sampleGradient(
        from: const Color(0xFF000000),
        to: const Color(0xFFFFFFFF),
        curve: curve,
        space: EasingColorSpace.srgb,
        samples: 7,
        strategy: SamplingStrategy.bezier,
      );
      for (var i = 0; i < result.stops.length; i++) {
        final u = i / 8;
        final v = 1 - u;
        final x = 3 * v * v * u * curve.a + 3 * v * u * u * curve.c + u * u * u;
        expect(result.stops[i], closeTo(x, 1e-15));
        expect(result.colors[i].r, curve.transform(result.stops[i]));
      }
      expect(result.stops[1], isNot(closeTo(1 / 8, 1e-3)));
    });

    test('Bezier rejects nonfinite cubics and falls back off-range x', () {
      expect(
        () => sampleGradient(
          from: _from,
          to: _to,
          curve: const Cubic(double.nan, 0, 0.5, 1),
          space: EasingColorSpace.srgb,
          strategy: SamplingStrategy.bezier,
        ),
        throwsArgumentError,
      );
      const offRange = Cubic(-0.4, 0.1, 1.3, 0.9);
      final expected = sampleGradient(
        from: _from,
        to: _to,
        curve: offRange,
        space: EasingColorSpace.srgb,
      );
      final result = sampleGradient(
        from: _from,
        to: _to,
        curve: offRange,
        space: EasingColorSpace.srgb,
        strategy: SamplingStrategy.bezier,
      );
      expect(result.colors, expected.colors);
      expect(result.stops, expected.stops);
    });

    test('Bezier falls back exactly for non-Cubic curves', () {
      for (final curve in [Curves.linear, Curves.elasticOut]) {
        final expected = sampleGradient(
          from: _from,
          to: _to,
          curve: curve,
          space: EasingColorSpace.oklab,
        );
        final result = sampleGradient(
          from: _from,
          to: _to,
          curve: curve,
          space: EasingColorSpace.oklab,
          strategy: SamplingStrategy.bezier,
        );
        expect(result.colors, expected.colors);
        expect(result.stops, expected.stops);
      }
    });

    test('nonpositive budgets fall back to one interior point', () {
      for (final strategy in SamplingStrategy.values) {
        final expected = sampleGradient(
          from: _from,
          to: _to,
          curve: Curves.easeInOut,
          space: EasingColorSpace.srgb,
          samples: 1,
          strategy: strategy,
        );
        for (final samples in [0, -20]) {
          final result = sampleGradient(
            from: _from,
            to: _to,
            curve: Curves.easeInOut,
            space: EasingColorSpace.srgb,
            samples: samples,
            strategy: strategy,
          );
          expect(result.colors, expected.colors);
          expect(result.stops, expected.stops);
        }
      }
    });

    test('all strategies retain exact Steps bands regardless of budget', () {
      for (final position in StepPosition.values) {
        final curve = StepsCurve(4, position: position);
        final expected = easeColorStops(
          colors: const [_from, _to],
          curve: curve,
          colorSpace: EasingColorSpace.oklch,
        );
        for (final strategy in SamplingStrategy.values) {
          final result = sampleGradient(
            from: _from,
            to: _to,
            curve: curve,
            space: EasingColorSpace.oklch,
            samples: 1,
            strategy: strategy,
          );
          expect(result.colors, expected.colors);
          expect(result.stops, expected.stops);
          final error = measureSamplingError(
            from: _from,
            to: _to,
            curve: curve,
            space: EasingColorSpace.oklch,
            generated: result,
          );
          expect(error.maximum, lessThan(1e-14));
        }
      }
    });

    test('transparent guards protect hidden RGB at both ends', () {
      const clear = Color(0x00000000);
      const white = Color(0xFFFFFFFF);
      for (final strategy in SamplingStrategy.values) {
        for (final reverse in [false, true]) {
          final from = reverse ? clear : white;
          final to = reverse ? white : clear;
          final result = sampleGradient(
            from: from,
            to: to,
            curve: Curves.easeInOut,
            space: EasingColorSpace.srgb,
            strategy: strategy,
          );
          expect(result.colors.first, from);
          expect(result.colors.last, to);
          final guardIndex = reverse ? 1 : result.colors.length - 2;
          expect(result.stops[guardIndex], reverse ? 0 : 1);
          expect(result.colors[guardIndex].a, 0);
          expect(result.colors[guardIndex].r, closeTo(1, 1e-12));
          expect(result.stops.toSet().length, lessThanOrEqualTo(17));
          expect(result.stops.length, lessThanOrEqualTo(18));
          expect(
            sampleStops(result, reverse ? 1e-4 : 1 - 1e-4).r,
            closeTo(1, 1e-12),
          );
        }
      }
    });

    test('adaptive terminates early for constant and linear paths', () {
      for (final to in [_from, _to]) {
        final result = sampleGradient(
          from: _from,
          to: to,
          curve: Curves.linear,
          space: EasingColorSpace.srgb,
          samples: 63,
          strategy: SamplingStrategy.adaptive,
        );
        expect(result.stops.length, 5);
        final error = measureSamplingError(
          from: _from,
          to: to,
          curve: Curves.linear,
          space: EasingColorSpace.srgb,
          generated: result,
        );
        expect(error.maximum, lessThan(1e-12));
      }
    });

    test('adaptive quarter probes find a midpoint-invisible oscillation', () {
      final result = sampleGradient(
        from: const Color(0xFF000000),
        to: const Color(0xFFFFFFFF),
        curve: const _RippleCurve(),
        space: EasingColorSpace.srgb,
        samples: 15,
        strategy: SamplingStrategy.adaptive,
      );
      expect(result.stops.length, 17);
      expect(result.stops.any((t) => (t * 8).roundToDouble() != t * 8), isTrue);
    });

    test('adaptive improves a sharp fade at equal point budget', () {
      EasedColorStops generate(SamplingStrategy strategy) => sampleGradient(
        from: const Color(0xFF000000),
        to: const Color(0x00000000),
        curve: Curves.easeInOutQuint,
        space: EasingColorSpace.srgb,
        strategy: strategy,
      );
      double maximum(SamplingStrategy strategy) => measureSamplingError(
        from: const Color(0xFF000000),
        to: const Color(0x00000000),
        curve: Curves.easeInOutQuint,
        space: EasingColorSpace.srgb,
        generated: generate(strategy),
      ).maximum;
      expect(
        maximum(SamplingStrategy.adaptive),
        lessThan(maximum(SamplingStrategy.uniform)),
      );
    });

    test('adaptive overshooting polar/alpha paths stay finite and bounded', () {
      for (final space in EasingColorSpace.values) {
        final result = sampleGradient(
          from: const Color(0x224F46E5),
          to: const Color(0xCCF97316),
          curve: Curves.elasticOut,
          space: space,
          samples: 31,
          strategy: SamplingStrategy.adaptive,
        );
        expect(result.stops.length, lessThanOrEqualTo(33));
        final error = measureSamplingError(
          from: const Color(0x224F46E5),
          to: const Color(0xCCF97316),
          curve: Curves.elasticOut,
          space: space,
          generated: result,
        );
        expect([
          error.maximum,
          error.p95,
          error.rms,
        ], everyElement(inInclusiveRange(0, 1)));
        expect(error.p95, lessThanOrEqualTo(error.maximum));
        expect(error.rms, lessThanOrEqualTo(error.maximum));
      }
    });
  });

  group('CPU interpolation and residuals', () {
    test('straight float RGBA differs from alpha-weighted mixing', () {
      final stops = (
        colors: const [Color(0x00FF0000), Color(0xFF0000FF)],
        stops: const [0.0, 1.0],
      );
      final midpoint = sampleStops(stops, 0.5);
      expect(midpoint.a, 0.5);
      expect(midpoint.r, 0.5);
      expect(midpoint.b, 0.5);
      expect(sampleStops(stops, 0.12345).a, closeTo(0.12345, 1e-14));
      expect(sampleStops(stops, -1), stops.colors.first);
      expect(sampleStops(stops, 2), stops.colors.last);
    });

    test('hard stops are right-continuous with exact outer endpoints', () {
      final stops = (
        colors: const [
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
        ],
        stops: const [0.0, 0.5, 0.5, 1.0],
      );
      expect(sampleStops(stops, 0.5), const Color(0xFFFFFFFF));
      expect(sampleStops(stops, 0.5 - 1e-9), const Color(0xFF000000));
    });

    test('sRGB model converts rather than retags wide-gamut inputs', () {
      const p3 = Color.from(
        alpha: 1,
        red: 1,
        green: 0.3,
        blue: 0.2,
        colorSpace: ColorSpace.displayP3,
      );
      final result = sampleStops((colors: [p3, p3], stops: [0.0, 1.0]), 0.5);
      expect(result.colorSpace, ColorSpace.sRGB);
      expect(result, p3.withValues(colorSpace: ColorSpace.sRGB));
    });

    test('alpha error is visible even with identical black RGB', () {
      const clear = Color(0x00000000);
      const halfBlack = Color.from(alpha: 0.5, red: 0, green: 0, blue: 0);
      expect(compositeError(clear, halfBlack), 0.5);
      expect(
        compositeError(clear, halfBlack, background: const Color(0xFF000000)),
        0.5,
      );
      expect(compositeError(clear, const Color(0x00FFFFFF)), 0);
    });

    test('source-over channels and default black/white maximum are exact', () {
      const a = Color.from(alpha: 0.3, red: 1, green: 0, blue: 0);
      const b = Color.from(alpha: 0.6, red: 0, green: 0, blue: 1);
      expect(compositeError(a, b), closeTo(0.6, 1e-12));
      expect(
        compositeError(a, b, background: const Color(0xFFFF0000)),
        closeTo(0.6, 1e-12),
      );
      expect(
        () => compositeError(a, b, background: const Color(0x00000000)),
        throwsAssertionError,
      );
    });

    test('measurement statistics include alpha-only discrepancies', () {
      final generated = (
        colors: const [Color(0x00000000), Color(0x00000000)],
        stops: const [0.0, 1.0],
      );
      final error = measureSamplingError(
        from: const Color(0xFF000000),
        to: const Color(0xFF000000),
        curve: Curves.linear,
        space: EasingColorSpace.srgb,
        generated: generated,
        positions: 3,
      );
      expect(error, (maximum: 1.0, p95: 1.0, rms: 1.0));
    });
  });
}

class _RippleCurve extends Curve {
  const _RippleCurve();

  @override
  double transformInternal(double t) => t + 0.02 * math.sin(8 * math.pi * t);
}
