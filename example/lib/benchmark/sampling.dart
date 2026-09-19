import 'dart:math' as math;
import 'dart:ui' show Color, ColorSpace;

import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/animation.dart';

/// Experimental stop placement, independent of interpolation color space.
enum SamplingStrategy { uniform, bezier, adaptive }

/// Samples the same eased color function using different stop placements.
///
/// [samples] is an interior-point budget, coerced to one when smaller. Smooth
/// strategies use at most `samples + 2` distinct positions. Transparent endpoint
/// guards can add zero-width stops beyond that budget. Steps retain the package's
/// exact bands and ignore this budget. Results are unmodifiable.
///
/// Bézier placement uses uniform parameter values to choose x coordinates of a
/// [Cubic], then evaluates [Curve.transform] at those coordinates, not its y
/// polynomial. Non-Cubic curves and finite Cubics whose x controls are outside
/// `[0, 1]` fall back to uniform placement. Nonfinite Cubic controls throw
/// [ArgumentError] before evaluating Flutter's transform. Adaptive placement
/// greedily splits the largest observed composite/alpha error, starting with up
/// to four uniform intervals and probing at quarters of each interval. Finite
/// probes cannot guarantee a bound for arbitrary curves or narrow spikes.
///
/// This experiment converts inputs to sRGB and emits only sRGB colors. It does
/// not evaluate wide-gamut stop interpolation or backend gamut handling.
EasedColorStops sampleGradient({
  required Color from,
  required Color to,
  required Curve curve,
  required EasingColorSpace space,
  int samples = 15,
  SamplingStrategy strategy = SamplingStrategy.uniform,
}) {
  final count = math.max(1, samples);
  if (strategy == SamplingStrategy.bezier && curve is Cubic) {
    final controls = [curve.a, curve.b, curve.c, curve.d];
    if (controls.any((value) => !value.isFinite)) {
      throw ArgumentError.value(
        curve,
        'curve',
        'Nonfinite cubic control points cannot be sampled or transformed.',
      );
    }
  }
  final cubicPlacementSupported =
      curve is Cubic &&
      curve.a >= 0 &&
      curve.a <= 1 &&
      curve.c >= 0 &&
      curve.c <= 1;
  if (strategy == SamplingStrategy.uniform ||
      curve is StepsCurve ||
      (strategy == SamplingStrategy.bezier && !cubicPlacementSupported)) {
    return easeColorStops(
      colors: [from, to],
      curve: curve,
      colorSpace: space,
      samplesPerTransition: count,
    );
  }

  Color evaluate(double t) => mixColors(from, to, curve.transform(t), space);
  final List<_Sample> points;
  if (strategy == SamplingStrategy.bezier) {
    final cubic = curve as Cubic;
    final divisions = count + 1;
    points = [];
    for (var i = 0; i <= divisions; i++) {
      final t = i == 0
          ? 0.0
          : i == divisions
          ? 1.0
          : _bezierX(i / divisions, cubic);
      points.add((t: t, color: evaluate(t)));
    }
  } else {
    final divisions = math.min(4, count + 1);
    points = [
      for (var i = 0; i <= divisions; i++)
        (t: i / divisions, color: evaluate(i / divisions)),
    ];
    final splits = [
      for (var i = 0; i < points.length - 1; i++)
        _probe(points[i], points[i + 1], evaluate),
    ];
    while (points.length < count + 2) {
      var best = 0;
      for (var i = 1; i < splits.length; i++) {
        if (splits[i].error > splits[best].error) best = i;
      }
      final split = splits[best];
      // Constant/linear paths stop early; rounded positions cannot loop forever.
      if (!split.error.isFinite ||
          split.error <= 1e-12 ||
          split.sample.t <= points[best].t ||
          split.sample.t >= points[best + 1].t) {
        break;
      }
      points.insert(best + 1, split.sample);
      splits[best] = _probe(points[best], points[best + 1], evaluate);
      splits.insert(
        best + 1,
        _probe(points[best + 1], points[best + 2], evaluate),
      );
    }
  }
  return _withEndpointGuards(points);
}

typedef _Sample = ({double t, Color color});
typedef _Split = ({_Sample sample, double error});

// With x controls inside [0, 1], x(u) is monotone and stays inside [0, 1], so
// positions need no clamping or reordering.
double _bezierX(double u, Cubic curve) {
  final v = 1 - u;
  return 3 * v * v * u * curve.a + 3 * v * u * u * curve.c + u * u * u;
}

_Split _probe(_Sample left, _Sample right, Color Function(double) evaluate) {
  final from = left.t == 0 && left.color.a == 0
      ? right.color.withValues(alpha: 0)
      : left.color;
  final to = right.t == 1 && right.color.a == 0
      ? left.color.withValues(alpha: 0)
      : right.color;
  var best = (sample: left, error: 0.0);
  for (final fraction in const [0.25, 0.5, 0.75]) {
    final t = left.t + (right.t - left.t) * fraction;
    final actual = evaluate(t);
    final error = compositeError(actual, _straightColor(from, to, fraction));
    if (error > best.error) {
      best = (sample: (t: t, color: actual), error: error);
    }
  }
  return best;
}

EasedColorStops _withEndpointGuards(List<_Sample> points) {
  final colors = <Color>[];
  final stops = <double>[];
  void emit(double t, Color color) {
    if (stops.isNotEmpty && stops.last == t && colors.last == color) return;
    stops.add(t);
    colors.add(color);
  }

  Color? lastVisible;
  for (var i = 0; i < points.length; i++) {
    final point = points[i];
    if (i == points.length - 1 && point.color.a == 0 && lastVisible != null) {
      emit(point.t, lastVisible.withValues(alpha: 0));
    }
    emit(point.t, point.color);
    if (i == 0 && point.color.a == 0 && point.color != points.last.color) {
      emit(point.t, points[1].color.withValues(alpha: 0));
    }
    if (point.color.a > 0) lastVisible = point.color;
  }
  return (
    colors: List<Color>.unmodifiable(colors),
    stops: List<double>.unmodifiable(stops),
  );
}

Color _srgb(Color color) => color.colorSpace == ColorSpace.sRGB
    ? color
    : color.withValues(colorSpace: ColorSpace.sRGB);

Color _straightColor(Color from, Color to, double t) {
  final a = _srgb(from);
  final b = _srgb(to);
  return Color.from(
    alpha: a.a + (b.a - a.a) * t,
    red: a.r + (b.r - a.r) * t,
    green: a.g + (b.g - a.g) * t,
    blue: a.b + (b.b - a.b) * t,
  );
}

/// CPU model of straight, floating-point sRGB RGBA interpolation between stops.
///
/// At an interior hard edge the last color at that position wins. Exact outer
/// endpoints retain the first/last colors, including hidden transparent RGB.
/// This models stop interpolation, not framebuffer precision or display output.
Color sampleStops(EasedColorStops generated, double position) {
  final (:colors, :stops) = generated;
  assert(
    colors.isNotEmpty && colors.length == stops.length,
    'Sampling requires a color for each stop and at least one stop.',
  );
  if (position <= stops.first) return _srgb(colors.first);
  if (position >= stops.last) return _srgb(colors.last);
  // Upper bound selects the right side of duplicated hard stops without a
  // zero-width division, and avoids scanning every stop at every error probe.
  var low = 0;
  var high = stops.length;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (stops[middle] <= position) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  final left = low - 1;
  return _straightColor(
    colors[left],
    colors[low],
    (position - stops[left]) / (stops[low] - stops[left]),
  );
}

/// Maximum absolute alpha or source-over sRGB channel difference, in `[0, 1]`.
///
/// With no [background], takes the maximum over opaque black and white. A given
/// background must be opaque. Hidden RGB at zero alpha has no visible error.
/// This numeric residual is not a perceptual color-difference metric.
double compositeError(Color expected, Color actual, {Color? background}) {
  assert(
    background == null || background.a == 1,
    'The source-over comparison requires an opaque background.',
  );
  final a = _srgb(expected);
  final b = _srgb(actual);
  var error = (a.a - b.a).abs();
  final backgrounds = background == null
      ? const [Color(0xFF000000), Color(0xFFFFFFFF)]
      : [_srgb(background)];
  for (final bg in backgrounds) {
    for (final (x, y, channel) in [
      (a.r, b.r, bg.r),
      (a.g, b.g, bg.g),
      (a.b, b.b, bg.b),
    ]) {
      final difference =
          x * a.a + channel * (1 - a.a) - y * b.a - channel * (1 - b.a);
      error = math.max(error, difference.abs());
    }
  }
  return error;
}

/// Measures uniform-grid CPU residuals against the unsampled eased color path.
///
/// Uses [compositeError] and the nearest-rank p95 of [positions] observations,
/// including both endpoints. Steps use their band values at the first endpoint,
/// matching [easeColorStops] rather than Curve's animation endpoint pinning.
({double maximum, double p95, double rms}) measureSamplingError({
  required Color from,
  required Color to,
  required Curve curve,
  required EasingColorSpace space,
  required EasedColorStops generated,
  int positions = 4097,
}) {
  assert(
    positions >= 2,
    'Error measurement needs both endpoints and at least two observations.',
  );
  final count = math.max(2, positions);
  final errors = <double>[];
  var squared = 0.0;
  for (var i = 0; i < count; i++) {
    final t = i / (count - 1);
    final eased = curve is StepsCurve
        ? curve.stepValue((t * curve.count).floor().clamp(0, curve.count))
        : curve.transform(t);
    final expected = mixColors(from, to, eased, space);
    final error = compositeError(expected, sampleStops(generated, t));
    errors.add(error);
    squared += error * error;
  }
  errors.sort();
  return (
    maximum: errors.last,
    p95: errors[(count * 0.95).ceil() - 1],
    rms: math.sqrt(squared / count),
  );
}
