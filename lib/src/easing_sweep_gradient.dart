import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'color_space.dart';
import 'eased_color_stops.dart';

/// A [SweepGradient] whose color transitions follow easing curves.
///
/// The factory synchronously samples compact source colors. Inherited
/// [createShader] then paints those generated stops through Flutter's native
/// sweep shader.
///
/// ```dart
/// DecoratedBox(
///   decoration: BoxDecoration(
///     gradient: EasingSweepGradient(
///       startAngle: 0,
///       endAngle: math.pi * 2,
///       colors: const [Colors.red, Colors.blue, Colors.red],
///       colorSpace: EasingColorSpace.oklch,
///     ),
///   ),
/// )
/// ```
///
/// [startAngle] and [endAngle] are radians measured clockwise from the positive
/// x-axis. Flutter normalizes angles outside a full turn; [tileMode] determines
/// the area outside the selected sector. A directional [center] needs the
/// `TextDirection` passed to [createShader].
///
/// Inherited [colors] and [stops] are generated shader data; [sourceColors] and
/// [sourceStops] are compact copies. Inherited [scale], [withOpacity],
/// [fromColor], and interpolation return a plain [SweepGradient]. They preserve
/// generated stops but discard easing metadata.
class EasingSweepGradient extends SweepGradient {
  /// Creates and samples an eased sweep gradient.
  ///
  /// Entry `i` of [transitionCurves] shapes `colors[i]` to `colors[i + 1]`;
  /// null uses [curve]. See [easeColorStops] for debug preconditions, stop
  /// normalization, count exceptions, and construction complexity.
  factory EasingSweepGradient({
    AlignmentGeometry center = Alignment.center,
    double startAngle = 0.0,
    double endAngle = math.pi * 2,
    required List<Color> colors,
    List<double>? stops,
    Curve curve = Curves.easeInOut,
    List<Curve?>? transitionCurves,
    EasingColorSpace colorSpace = EasingColorSpace.oklab,
    int samplesPerTransition = defaultSamplesPerTransition,
    TileMode tileMode = TileMode.clamp,
    GradientTransform? transform,
  }) {
    final EasedColorStops eased = easeColorStops(
      colors: colors,
      stops: stops,
      curve: curve,
      transitionCurves: transitionCurves,
      colorSpace: colorSpace,
      samplesPerTransition: samplesPerTransition,
    );
    return EasingSweepGradient._(
      center: center,
      startAngle: startAngle,
      endAngle: endAngle,
      easedColors: eased.colors,
      easedStops: eased.stops,
      sourceColors: List<Color>.unmodifiable(colors),
      sourceStops: stops == null ? null : List<double>.unmodifiable(stops),
      curve: curve,
      transitionCurves: transitionCurves == null
          ? null
          : List<Curve?>.unmodifiable(transitionCurves),
      colorSpace: colorSpace,
      samplesPerTransition: samplesPerTransition,
      tileMode: tileMode,
      transform: transform,
    );
  }

  const EasingSweepGradient._({
    required super.center,
    required super.startAngle,
    required super.endAngle,
    required List<Color> easedColors,
    required List<double> easedStops,
    required this.sourceColors,
    required this.sourceStops,
    required this.curve,
    required this.transitionCurves,
    required this.colorSpace,
    required this.samplesPerTransition,
    required super.tileMode,
    required super.transform,
  }) : super(colors: easedColors, stops: easedStops);

  /// The colors passed to the factory before intermediate stops were inserted.
  final List<Color> sourceColors;

  /// The positions passed to the factory, or null when they were implied.
  final List<double>? sourceStops;

  /// The fallback easing curve used by every transition without an override.
  final Curve curve;

  /// Per-transition curve overrides, with null entries falling back to [curve].
  final List<Curve?>? transitionCurves;

  /// The color space used to calculate intermediate colors.
  final EasingColorSpace colorSpace;

  /// Requested interior samples per positive-width, non-stepped transition.
  ///
  /// Transparent endpoint guards and deduplication can change the final number
  /// of inherited [colors] and [stops]. See [easeColorStops].
  final int samplesPerTransition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EasingSweepGradient &&
          other.center == center &&
          other.startAngle == startAngle &&
          other.endAngle == endAngle &&
          other.tileMode == tileMode &&
          other.transform == transform &&
          listEquals(other.sourceColors, sourceColors) &&
          listEquals(other.sourceStops, sourceStops) &&
          other.curve == curve &&
          listEquals(other.transitionCurves, transitionCurves) &&
          other.colorSpace == colorSpace &&
          other.samplesPerTransition == samplesPerTransition;

  @override
  int get hashCode => Object.hash(
    center,
    startAngle,
    endAngle,
    tileMode,
    transform,
    Object.hashAll(sourceColors),
    sourceStops == null ? null : Object.hashAll(sourceStops!),
    curve,
    transitionCurves == null ? null : Object.hashAll(transitionCurves!),
    colorSpace,
    samplesPerTransition,
  );

  @override
  String toString() =>
      'EasingSweepGradient(center: $center, startAngle: $startAngle, '
      'endAngle: $endAngle, sourceColors: $sourceColors, '
      'sourceStops: $sourceStops, curve: $curve, '
      'transitionCurves: $transitionCurves, colorSpace: ${colorSpace.name}, '
      'samplesPerTransition: $samplesPerTransition, tileMode: $tileMode, '
      'transform: $transform, generatedStops: ${colors.length})';
}
