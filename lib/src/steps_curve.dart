import 'package:flutter/animation.dart';

/// Where a [StepsCurve] places its jumps, mirroring the `<step-position>`
/// keywords of the CSS `steps()` easing function.
enum StepPosition {
  /// The curve jumps at the start of every interval, so the first band already
  /// carries a value above zero and the start color is never shown.
  ///
  /// Equivalent to CSS `steps(n, jump-start)`, also spelled `start`.
  jumpStart,

  /// The curve jumps at the end of every interval, so the first band holds the
  /// start color and the end color is never shown.
  ///
  /// Equivalent to CSS `steps(n, jump-end)`, also spelled `end`. This is the
  /// CSS default and the default here.
  jumpEnd,

  /// The curve jumps at both ends, so neither the start nor the end color is
  /// shown as a band.
  ///
  /// Equivalent to CSS `steps(n, jump-both)`.
  jumpBoth,

  /// The curve jumps at neither end, so the bands run from the start color all
  /// the way to the end color.
  ///
  /// Equivalent to CSS `steps(n, jump-none)`. This is usually the best looking
  /// choice for a banded gradient, because both of the colors you asked for
  /// actually appear. Requires a [StepsCurve.count] of at least 2.
  jumpNone,
}

/// A staircase curve equivalent to the CSS `steps(count, position)` easing
/// function.
///
/// Used with an easing gradient this produces hard color bands instead of a
/// smooth fade. The gradient samplers recognise this curve and emit exact
/// duplicated stops at the band edges, so the bands have genuinely hard edges
/// rather than very short ramps, and `samplesPerTransition` is ignored.
///
/// ```dart
/// EasingLinearGradient(
///   colors: const [Colors.black, Colors.white],
///   curve: const StepsCurve(5, position: StepPosition.jumpNone),
/// )
/// ```
///
/// It is also a normal [Curve], so it can drive animations. One deviation to be
/// aware of in that role: [Curve.transform] is contractually required to map 0
/// to 0 and 1 to 1. For [StepPosition.jumpStart] and
/// [StepPosition.jumpBoth], the value at exactly `t == 0` is therefore 0 rather
/// than the raised first band. Gradient sampling is unaffected because it reads
/// band values through [stepValue]. Native renderers can choose the preceding
/// band at the single coordinate shared by two duplicated hard stops; this does
/// not create a visible ramp.
///
/// [count] must be at least 1, and [StepPosition.jumpNone] requires at least
/// 2. Debug assertions enforce those preconditions while preserving const use.
class StepsCurve extends Curve {
  /// Creates a staircase curve with [count] intervals.
  ///
  /// In debug builds, asserts that [count] is at least one and that
  /// [StepPosition.jumpNone] has at least two intervals. These are API
  /// preconditions in release builds too. Assertion validation preserves the
  /// const constructor required for gradients declared in const configuration.
  const StepsCurve(this.count, {this.position = StepPosition.jumpEnd})
    : assert(
        count >= 1,
        'A steps curve needs at least one interval to step through.',
      ),
      assert(
        count >= 2 || position != StepPosition.jumpNone,
        'StepPosition.jumpNone needs at least two intervals.',
      );

  /// The number of equal width intervals the transition is divided into.
  ///
  /// This is the number of visible bands for every [StepPosition] except
  /// [StepPosition.jumpBoth], which shows `count` bands plus the end color at
  /// the very end.
  final int count;

  /// Where the jumps happen.
  final StepPosition position;

  /// The number of jumps the output value is divided into.
  int get _jumps => switch (position) {
    StepPosition.jumpStart || StepPosition.jumpEnd => count,
    StepPosition.jumpBoth => count + 1,
    StepPosition.jumpNone => count - 1,
  };

  /// Whether the step index is raised by one before being turned into a value.
  bool get _raisesStep =>
      position == StepPosition.jumpStart || position == StepPosition.jumpBoth;

  /// The output value held during step [stepIndex].
  ///
  /// Steps `0` through `count - 1` are the bands the curve holds across the
  /// transition; step `count` is the value at exactly the end of the
  /// transition, which for [StepPosition.jumpEnd] and [StepPosition.jumpBoth]
  /// differs from the last band and so forms the final jump.
  ///
  /// This is the CSS `steps()` plateau value without the endpoint pinning that
  /// [Curve.transform] applies. Throws [RangeError] unless [stepIndex] is between
  /// 0 and [count], inclusive.
  double stepValue(int stepIndex) {
    RangeError.checkValueInInterval(stepIndex, 0, count, 'stepIndex');
    final int jumps = _jumps;
    final int raised = _raisesStep ? stepIndex + 1 : stepIndex;
    return raised.clamp(0, jumps) / jumps;
  }

  @override
  double transformInternal(double t) {
    // transform() has already handled t == 0 and t == 1, so t is strictly
    // inside the range and the floor lands on a real band.
    final int step = (t * count).floor().clamp(0, count - 1);
    return stepValue(step);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepsCurve &&
          other.runtimeType == runtimeType &&
          other.count == count &&
          other.position == position;

  @override
  int get hashCode => Object.hash(count, position);

  @override
  String toString() => 'StepsCurve($count, ${position.name})';
}
