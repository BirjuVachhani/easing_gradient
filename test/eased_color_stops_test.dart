import 'dart:ui' show ColorSpace;

import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('easeColorStops', () {
    test('has exact endpoints and expected default count', () {
      const from = Color(0xFF4F46E5);
      const to = Color(0x00F97316);
      final result = easeColorStops(colors: const [from, to]);
      // A transparent endpoint adds one zero-width limiting-color stop so
      // Flutter's straight-RGBA shader interpolation cannot leak hidden RGB.
      expect(result.colors.length, 18);
      expect(result.stops.length, 18);
      expect(result.colors.first, from);
      expect(result.colors.last, to);
      expect(result.stops.first, 0);
      expect(result.stops.last, 1);
    });

    test('deduplicates boundaries across multiple transitions', () {
      final result = easeColorStops(
        colors: const [Color(0xFFFF0000), Color(0xFF00FF00), Color(0xFF0000FF)],
        stops: const [0, 0.3, 1],
        samplesPerTransition: 3,
      );
      expect(result.colors.length, 9);
      expect(result.stops.where((stop) => stop == 0.3), [0.3]);
      expect(result.colors[4], const Color(0xFF00FF00));
    });

    test('transparent endpoints carry limiting RGB beside exact input', () {
      final result = easeColorStops(
        colors: const [Color(0xFFFFFFFF), Color(0x00000000)],
        curve: Curves.linear,
        colorSpace: EasingColorSpace.srgb,
        samplesPerTransition: 3,
      );
      expect(result.stops[result.stops.length - 2], 1);
      expect(result.stops.last, 1);
      expect(result.colors[result.colors.length - 2].a, 0);
      expect(result.colors[result.colors.length - 2].r, closeTo(1, 1e-6));
      expect(result.colors.last, const Color(0x00000000));
    });

    test('linear sRGB samples match Color.lerp for opaque colors', () {
      const from = Color(0xFF123456);
      const to = Color(0xFFFEDCBA);
      final result = easeColorStops(
        colors: const [from, to],
        curve: Curves.linear,
        colorSpace: EasingColorSpace.srgb,
        samplesPerTransition: 7,
      );
      for (var i = 0; i < result.stops.length; i++) {
        final expected = Color.lerp(from, to, result.stops[i])!;
        expect(result.colors[i].r, closeTo(expected.r, 1 / 255));
        expect(result.colors[i].g, closeTo(expected.g, 1 / 255));
        expect(result.colors[i].b, closeTo(expected.b, 1 / 255));
      }
    });

    test('easeInOut has an exact midpoint sample', () {
      final result = easeColorStops(
        colors: const [Color(0xFF000000), Color(0xFFFFFFFF)],
        colorSpace: EasingColorSpace.srgb,
      );
      final midpoint = result.stops.indexOf(0.5);
      expect(midpoint, isNonNegative);
      expect(result.colors[midpoint].r, closeTo(0.5, 1e-6));
    });

    test('uses per-transition curves with null fallback', () {
      final result = easeColorStops(
        colors: const [Color(0xFF000000), Color(0xFF808080), Color(0xFFFFFFFF)],
        curve: Curves.easeIn,
        transitionCurves: const [Curves.linear, null],
        colorSpace: EasingColorSpace.srgb,
        samplesPerTransition: 3,
      );
      // 0.25 progress in the first transition is linearly one quarter to gray.
      expect(result.colors[1].r, closeTo(0.125, 2 / 255));
      // The equivalent point in the second transition is ease-in, below linear.
      expect(result.colors[5].r, lessThan(0.625));
    });

    test('normalizes out of range and descending stops', () {
      final result = easeColorStops(
        colors: const [Color(0xFF000000), Color(0xFF808080), Color(0xFFFFFFFF)],
        stops: const [-1, 0.7, 0.2],
        samplesPerTransition: 1,
      );
      expect(result.stops.first, 0);
      expect(result.stops.last, 0.7);
      for (var i = 1; i < result.stops.length; i++) {
        expect(result.stops[i], greaterThanOrEqualTo(result.stops[i - 1]));
      }
    });

    test('keeps a zero-width transition as a hard edge', () {
      final result = easeColorStops(
        colors: const [Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFFFF0000)],
        stops: const [0, 0.5, 0.5],
        samplesPerTransition: 1,
      );
      final indices = <int>[
        for (var i = 0; i < result.stops.length; i++)
          if (result.stops[i] == 0.5) i,
      ];
      expect(indices.length, greaterThanOrEqualTo(2));
      expect(
        result.colors[indices[indices.length - 2]],
        const Color(0xFFFFFFFF),
      );
      expect(result.colors[indices.last], const Color(0xFFFF0000));
    });

    test('returned lists are unmodifiable', () {
      final result = easeColorStops(
        colors: const [Color(0xFF000000), Color(0xFFFFFFFF)],
      );
      expect(
        () => result.colors.add(const Color(0xFFFF0000)),
        throwsUnsupportedError,
      );
      expect(() => result.stops.add(1), throwsUnsupportedError);
    });

    test('asserts invalid input with explanatory messages', () {
      expect(
        () => easeColorStops(colors: const [Color(0xFF000000)]),
        throwsAssertionError,
      );
      expect(
        () => easeColorStops(
          colors: const [Color(0xFF000000), Color(0xFFFFFFFF)],
          stops: const [0],
        ),
        throwsAssertionError,
      );
      expect(
        () => easeColorStops(
          colors: const [Color(0xFF000000), Color(0xFFFFFFFF)],
          transitionCurves: const [Curves.linear, Curves.easeIn],
        ),
        throwsAssertionError,
      );
      expect(
        () => easeColorStops(
          colors: const [Color(0xFF000000), Color(0xFFFFFFFF)],
          samplesPerTransition: 0,
        ),
        throwsAssertionError,
      );
    });

    // Conversion accuracy belongs to color_space_test.dart. These cases cover
    // what the sampler owns: which stops carry the requested encoding.
    group('outputColorSpace', () {
      const p3Red = Color.from(
        alpha: 1,
        red: 1,
        green: 0,
        blue: 0,
        colorSpace: ColorSpace.displayP3,
      );

      test('defaults to sRGB so existing callers see no change', () {
        final result = easeColorStops(
          colors: const [p3Red, Color(0xFF00FF00)],
          samplesPerTransition: 3,
        );
        expect(result.colors.map((color) => color.colorSpace).toSet(), {
          ColorSpace.sRGB,
        });
      });

      test('tags interior samples and transparent guards alike', () {
        final result = easeColorStops(
          colors: const [Color(0xFFFFFFFF), Color(0x00000000)],
          samplesPerTransition: 3,
          outputColorSpace: ColorSpace.displayP3,
        );
        // A transparent endpoint adds a zero-width limiting-color stop. It is
        // read by the same shader as every other stop, so it has to share the
        // encoding rather than fall back to sRGB.
        expect(result.colors.map((color) => color.colorSpace).toSet(), {
          ColorSpace.displayP3,
        }, reason: 'A single shader cannot read stops from two encodings.');
      });

      test('converts sRGB input rather than relabelling its channels', () {
        const srgbRed = Color(0xFFFF0000);
        final result = easeColorStops(
          colors: const [srgbRed, Color(0xFF0000FF)],
          samplesPerTransition: 3,
          outputColorSpace: ColorSpace.displayP3,
        );
        final first = result.colors.first;
        expect(first.colorSpace, ColorSpace.displayP3);
        // sRGB red is inside P3, so it lands short of the P3 primary. Equal
        // channel numbers would mean the values were retagged, not converted.
        expect(first.r, lessThan(1));
        expect(first.r, greaterThan(0.9));
        expect(first.g, greaterThan(0));
      });
    });
  });
}
