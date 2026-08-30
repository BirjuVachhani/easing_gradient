import 'dart:ui';

import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepsCurve', () {
    test('matches CSS jump-end plateaus', () {
      const curve = StepsCurve(4);
      expect(curve.transform(0.1), 0);
      expect(curve.transform(0.3), 0.25);
      expect(curve.transform(0.6), 0.5);
      expect(curve.transform(0.9), 0.75);
      expect(curve.transform(1), 1);
    });

    test('implements every position', () {
      expect(
        const StepsCurve(4, position: StepPosition.jumpStart).stepValue(0),
        0.25,
      );
      expect(
        const StepsCurve(4, position: StepPosition.jumpEnd).stepValue(0),
        0,
      );
      expect(
        const StepsCurve(4, position: StepPosition.jumpBoth).stepValue(0),
        0.2,
      );
      expect(
        const StepsCurve(4, position: StepPosition.jumpNone).stepValue(0),
        0,
      );
      expect(
        const StepsCurve(4, position: StepPosition.jumpNone).stepValue(3),
        1,
      );
    });

    test('validates count invariants', () {
      expect(() => StepsCurve(0), throwsAssertionError);
      expect(
        () => StepsCurve(1, position: StepPosition.jumpNone),
        throwsAssertionError,
      );
      expect(() => StepsCurve(4).stepValue(5), throwsRangeError);
    });

    test('sampler emits duplicated positions for exact hard edges', () {
      final result = easeColorStops(
        colors: const [Color(0xFF000000), Color(0xFFFFFFFF)],
        curve: const StepsCurve(4, position: StepPosition.jumpNone),
      );
      final duplicated = <double>[];
      for (var i = 1; i < result.stops.length; i++) {
        if (result.stops[i] == result.stops[i - 1] &&
            result.colors[i] != result.colors[i - 1]) {
          duplicated.add(result.stops[i]);
        }
      }
      expect(duplicated, [0.25, 0.5, 0.75]);
      expect(result.colors.first, const Color(0xFF000000));
      expect(result.colors.last, const Color(0xFFFFFFFF));
    });
  });
}
