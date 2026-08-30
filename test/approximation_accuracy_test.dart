import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

// Compares the generated-stop approximation with a 2,049-position continuous
// CPU reference. The visible error metric uses premultiplied channels and models
// Flutter's straight-RGBA interpolation between generated stops.
void main() {
  const from = Color(0xFF4F46E5);
  const to = Color(0x00F97316);

  test('recommended defaults stay below one 8-bit step', () {
    for (final space in <EasingColorSpace>[
      EasingColorSpace.srgb,
      EasingColorSpace.linearRgb,
      EasingColorSpace.oklab,
    ]) {
      final error = maxApproximationError(
        from: from,
        to: to,
        curve: Curves.easeInOut,
        space: space,
        samples: defaultSamplesPerTransition,
      );
      expect(
        error,
        lessThan(1 / 255),
        reason:
            'Curves.easeInOut in $space should be sub-8-bit accurate at '
            'the default sample count; measured '
            '${(error * 255).toStringAsFixed(3)} LSB.',
      );
    }
  });

  test('more samples reduce approximation error for sharp curves', () {
    for (final curve in <Curve>[Curves.easeInOutQuint, Curves.elasticOut]) {
      final errors = <double>[
        for (final samples in <int>[7, 15, 31, 63])
          maxApproximationError(
            from: from,
            to: to,
            curve: curve,
            space: EasingColorSpace.oklab,
            samples: samples,
          ),
      ];
      for (var i = 1; i < errors.length; i++) {
        expect(
          errors[i],
          lessThan(errors[i - 1]),
          reason: 'Doubling the sample density should reduce error for $curve.',
        );
      }
      // Kept visible under `flutter test -r expanded` as honest data for docs.
      // ignore: avoid_print
      print(
        '$curve errors in 8-bit steps: '
        '${errors.map((e) => (e * 255).toStringAsFixed(3)).join(', ')}',
      );
    }
  });

  test('reports representative errors without imposing a false universal bound', () {
    const curves = <Curve>[
      Curves.easeInOut,
      Curves.easeInOutCubic,
      Curves.easeInOutQuint,
      Curves.easeOutBack,
      Curves.elasticOut,
    ];
    for (final curve in curves) {
      for (final space in EasingColorSpace.values) {
        final error = maxApproximationError(
          from: from,
          to: to,
          curve: curve,
          space: space,
          samples: defaultSamplesPerTransition,
        );
        // Polar paths and out-of-gamut overshoot can have more error because
        // each generated stop is clipped to sRGB before the native shader sees
        // it. The Accuracy Lab makes this tradeoff visible instead of promising
        // that every curve and color pair shares the default path's bound.
        expect(error, inInclusiveRange(0, 1));
      }
    }
  });
}

/// Measures the worst premultiplied channel error between the true curve and
/// the piecewise linear color interpolation a GPU performs between generated
/// stops.
double maxApproximationError({
  required Color from,
  required Color to,
  required Curve curve,
  required EasingColorSpace space,
  required int samples,
}) {
  final generated = easeColorStops(
    colors: [from, to],
    curve: curve,
    colorSpace: space,
    samplesPerTransition: samples,
  );
  double maximum = 0;
  for (var pixel = 0; pixel <= 2048; pixel++) {
    final t = pixel / 2048;
    final exact = mixColors(from, to, curve.transform(t), space);
    final sampled = sampleGeneratedStops(generated, t);
    maximum = <double>[
      maximum,
      (exact.a - sampled.a).abs(),
      (exact.r * exact.a - sampled.r * sampled.a).abs(),
      (exact.g * exact.a - sampled.g * sampled.a).abs(),
      (exact.b * exact.a - sampled.b * sampled.a).abs(),
    ].reduce((a, b) => a > b ? a : b);
  }
  return maximum;
}

Color sampleGeneratedStops(EasedColorStops generated, double t) {
  if (t <= generated.stops.first) return generated.colors.first;
  for (var i = 1; i < generated.stops.length; i++) {
    if (t <= generated.stops[i]) {
      final start = generated.stops[i - 1];
      final end = generated.stops[i];
      if (end == start) return generated.colors[i];
      // Impeller interpolates straight RGBA between supplied stops and
      // premultiplies the resulting fragment. Color.lerp models that straight
      // interpolation; the error metric premultiplies both results afterwards.
      return Color.lerp(
        generated.colors[i - 1],
        generated.colors[i],
        (t - start) / (end - start),
      )!;
    }
  }
  return generated.colors.last;
}
