import 'dart:math' as math;

import 'package:flutter/animation.dart';

import 'color_space.dart';
import 'steps_curve.dart';

/// Parallel lists of colors and stop positions, ready to hand to any API that
/// takes a gradient: the painting gradients, `dart:ui`'s `Gradient`, or your own
/// `CustomPainter`.
///
/// Both lists have the same length and are unmodifiable. Destructure them with
/// a record pattern:
///
/// ```dart
/// final (:colors, :stops) = easeColorStops(colors: [Colors.black, Colors.transparent]);
/// ```
typedef EasedColorStops = ({List<Color> colors, List<double> stops});

/// The requested number of interior samples for each smooth transition.
///
/// The default of 15 matches postcss-easing-gradients. Fifteen interior points
/// divide a transition into 16 equal intervals and evaluate 17 positions when
/// the two endpoints are included. Because 16 is even, progress `0.5` is one of
/// those positions.
///
/// Tests show sub-8-bit visible-channel error for representative
/// `Curves.easeInOut` fades in sRGB, linear RGB, and OKLab. This is not a
/// universal error bound. Sharp or overshooting curves, polar color spaces, and
/// paths that clip against the sRGB gamut can need 31 or 63 interior samples.
const int defaultSamplesPerTransition = 15;

/// Samples a set of color stops along an easing [curve].
///
/// Flutter's gradients fade between neighbouring stops in a straight line,
/// which is what creates the hard edge you see where a scrim begins or ends.
/// This function traces the curve instead, by inserting
/// [samplesPerTransition] extra stops into every transition and computing the
/// color at each one. The renderer still interpolates linearly between the
/// stops it is given, but the stops are now close enough together that the
/// result follows the curve.
///
/// Sampling is synchronous on every call. For `k = colors.length - 1`
/// transitions and `n = samplesPerTransition`, time and generated-list memory
/// are both `O(k * n)`, plus constant-cost color conversion per sample. Painting
/// later uses an ordinary Flutter gradient with those stops. There is no
/// per-frame curve work only when the caller retains the result or otherwise
/// avoids recreating it on every frame. Cache stable gradients when they use
/// many stops or sit inside frequently rebuilt widgets.
///
/// Parameters:
///
/// * [colors] defines compact source colors and must contain at least two.
/// * [stops] positions the source colors like `Gradient.stops`. Null spreads
///   them evenly. Values are clamped to `[0, 1]`, NaN inherits the previous
///   resolved position (or zero first), and descending values are raised to the
///   previous position. Equal positions deliberately create hard edges.
/// * [curve] shapes every transition. [StepsCurve] creates exact bands and
///   ignores [samplesPerTransition].
/// * [transitionCurves] maps by transition index: entry `i` controls
///   `colors[i]` to `colors[i + 1]`; null falls back to [curve].
/// * [colorSpace] selects the path used to calculate intermediate colors.
/// * [samplesPerTransition] requests interior samples for each positive-width,
///   non-stepped transition. Raise it for sharp curves or gamut-clipped paths.
///
/// Debug builds assert that [colors] has at least two entries, [stops] has one
/// entry per color, [transitionCurves] has one entry per transition, and
/// [samplesPerTransition] is positive. These are API preconditions, not release
/// fallbacks to rely on. The release implementation degrades defensively by
/// duplicating a missing color, coercing the sample count to one, padding or
/// truncating stop data, and applying only available transition overrides.
///
/// For smooth, positive-width, nontransparent transitions with no deduplication,
/// the output size is `(colors.length - 1) * (samplesPerTransition + 1) + 1`.
/// Two opaque colors at the default produce 17 entries. A fully transparent
/// endpoint can add a zero-width limiting-color stop, producing 18. Shared
/// boundaries and repeated colors can deduplicate entries, coincident source
/// stops create hard edges, and [StepsCurve] uses its own band-based count.
EasedColorStops easeColorStops({
  required List<Color> colors,
  List<double>? stops,
  Curve curve = Curves.easeInOut,
  List<Curve?>? transitionCurves,
  EasingColorSpace colorSpace = EasingColorSpace.oklab,
  int samplesPerTransition = defaultSamplesPerTransition,
}) {
  assert(
    colors.length >= 2,
    'A gradient is a transition between colors, so at least two are needed. '
    'Got ${colors.length}.',
  );
  assert(
    stops == null || stops.length == colors.length,
    'stops must position every color, so it needs exactly ${colors.length} '
    'entries to match colors.',
  );
  assert(
    transitionCurves == null || transitionCurves.length == colors.length - 1,
    'transitionCurves overrides the curve of each transition, and '
    '${colors.length} colors form ${colors.length - 1} transitions.',
  );
  assert(
    samplesPerTransition >= 1,
    'At least one sample per transition is needed for the curve to show up '
    'at all. Got $samplesPerTransition.',
  );

  // Defensive fallbacks so a release build degrades instead of crashing.
  if (colors.length < 2) {
    final Color single = colors.isEmpty
        ? const Color(0x00000000)
        : colors.first;
    return (
      colors: List<Color>.unmodifiable(<Color>[single, single]),
      stops: List<double>.unmodifiable(<double>[0.0, 1.0]),
    );
  }
  final int samples = math.max(1, samplesPerTransition);

  final List<double> resolvedStops = _resolveStops(colors.length, stops);

  final List<Color> outColors = <Color>[];
  final List<double> outStops = <double>[];

  void emit(double stop, Color color) {
    // Never step backwards, so the output always satisfies the increasing
    // order that gradients require even if floating point drifts.
    final double position = outStops.isEmpty
        ? stop
        : math.max(stop, outStops.last);
    // Drop a stop only when it repeats the previous one exactly. That removes
    // the sample shared by the end of one transition and the start of the next,
    // while leaving deliberate hard edges (same position, different color)
    // untouched.
    if (outStops.isNotEmpty &&
        outStops.last == position &&
        outColors.last == color) {
      return;
    }
    outStops.add(position);
    outColors.add(color);
  }

  for (int i = 0; i < colors.length - 1; i++) {
    final Color from = colors[i];
    final Color to = colors[i + 1];
    final double start = resolvedStops[i];
    final double end = resolvedStops[i + 1];
    final Curve activeCurve =
        (transitionCurves != null &&
            i < transitionCurves.length &&
            transitionCurves[i] != null)
        ? transitionCurves[i]!
        : curve;

    if (end <= start) {
      // A zero width transition is a hard edge the caller asked for.
      emit(start, from);
      emit(start, to);
      continue;
    }

    if (activeCurve is StepsCurve) {
      _emitSteps(
        emit: emit,
        curve: activeCurve,
        from: from,
        to: to,
        start: start,
        end: end,
        colorSpace: colorSpace,
      );
      continue;
    }

    final int divisions = samples + 1;
    Color? lastInteriorColor;
    for (int step = 0; step <= divisions; step++) {
      // Dividing rather than multiplying by a step size keeps the last progress
      // exactly 1.0, which Curve.transform relies on to return the end value.
      final double progress = step / divisions;
      final double eased = activeCurve.transform(progress);
      Color color = mixColors(from, to, eased, colorSpace);

      // Native Flutter gradients interpolate supplied stops in straight RGBA
      // and premultiply only after that interpolation. A fully transparent stop
      // can therefore leak its hidden RGB into the final interval. Give the
      // renderer a transparent stop carrying the limiting visible RGB first,
      // then preserve the caller's exact transparent endpoint at the same
      // position. The duplicate has zero visual width but keeps endpoint data.
      if (step == divisions && to.a == 0 && lastInteriorColor != null) {
        emit(end, lastInteriorColor.withValues(alpha: 0));
      }
      if (step == 0 && from.a == 0 && from != to) {
        final Color firstInterior = mixColors(
          from,
          to,
          activeCurve.transform(1 / divisions),
          colorSpace,
        );
        emit(start, from);
        emit(start, firstInterior.withValues(alpha: 0));
      } else {
        emit(_locationAt(start, end, progress), color);
      }
      if (step < divisions && color.a > 0) lastInteriorColor = color;
    }
  }

  return (
    colors: List<Color>.unmodifiable(outColors),
    stops: List<double>.unmodifiable(outStops),
  );
}

/// Emits the exact hard bands of a [StepsCurve] across one transition.
///
/// Each band is written as a pair of stops holding the same color, so the jump
/// between two bands lands on a single position with two different colors,
/// which is how a gradient expresses a hard edge.
void _emitSteps({
  required void Function(double stop, Color color) emit,
  required StepsCurve curve,
  required Color from,
  required Color to,
  required double start,
  required double end,
  required EasingColorSpace colorSpace,
}) {
  final int count = curve.count;
  for (int band = 0; band < count; band++) {
    final Color bandColor = mixColors(
      from,
      to,
      curve.stepValue(band),
      colorSpace,
    );
    emit(_locationAt(start, end, band / count), bandColor);
    emit(_locationAt(start, end, (band + 1) / count), bandColor);
  }
  // For jump-end and jump-both the value at the very end differs from the last
  // band, which is the final jump. Otherwise this repeats the last stop and the
  // caller's dedup drops it.
  emit(end, mixColors(from, to, curve.stepValue(count), colorSpace));
}

/// Positions a sample within a transition, pinning the ends so the first and
/// last stops land exactly on the caller's positions.
double _locationAt(double start, double end, double progress) {
  if (progress <= 0) return start;
  if (progress >= 1) return end;
  return start + (end - start) * progress;
}

/// Produces one stop per color, either evenly spread or taken from [stops] and
/// forced into the increasing, in range order gradients require.
List<double> _resolveStops(int colorCount, List<double>? stops) {
  if (stops == null) {
    final int lastIndex = colorCount - 1;
    return <double>[for (int i = 0; i <= lastIndex; i++) i / lastIndex];
  }

  final List<double> resolved = <double>[];
  for (int i = 0; i < colorCount; i++) {
    double value = i < stops.length ? stops[i] : 1.0;
    if (value.isNaN) value = i == 0 ? 0.0 : resolved[i - 1];
    value = value.clamp(0.0, 1.0);
    if (i > 0 && value < resolved[i - 1]) value = resolved[i - 1];
    resolved.add(value);
  }
  return resolved;
}
