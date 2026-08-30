import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'color_space.dart';
import 'eased_color_stops.dart';

/// A [RadialGradient] whose color transitions follow easing curves.
///
/// The factory synchronously samples the compact source colors, then inherited
/// [createShader] paints the generated stops through Flutter's native radial
/// shader. Retain stable instances to avoid repeating construction work.
///
/// ```dart
/// DecoratedBox(
///   decoration: BoxDecoration(
///     gradient: EasingRadialGradient(
///       center: const Alignment(-0.4, -0.5),
///       radius: 0.9,
///       colors: const [Colors.white, Colors.transparent],
///       curve: Curves.easeOutCubic,
///     ),
///   ),
/// )
/// ```
///
/// [center] and [focal] resolve like Flutter alignments. [radius] and
/// [focalRadius] are fractions of the paint box's shortest side. A positive
/// [focalRadius] cannot create a valid Flutter shader when [center] and [focal]
/// both resolve to `Offset.zero`. Directional alignments need the
/// `TextDirection` passed to [createShader].
///
/// Inherited [colors] and [stops] are generated shader data; [sourceColors] and
/// [sourceStops] are defensive copies of compact input. Inherited [scale],
/// [withOpacity], [fromColor], and interpolation return a plain
/// [RadialGradient]. They preserve generated stops but discard easing metadata.
class EasingRadialGradient extends RadialGradient {
  /// Creates and samples an eased radial gradient.
  ///
  /// Entry `i` of [transitionCurves] shapes `colors[i]` to `colors[i + 1]`;
  /// null uses [curve]. See [easeColorStops] for debug preconditions, stop
  /// normalization, count exceptions, and construction complexity.
  factory EasingRadialGradient({
    AlignmentGeometry center = Alignment.center,
    double radius = 0.5,
    required List<Color> colors,
    List<double>? stops,
    Curve curve = Curves.easeInOut,
    List<Curve?>? transitionCurves,
    EasingColorSpace colorSpace = EasingColorSpace.oklab,
    int samplesPerTransition = defaultSamplesPerTransition,
    TileMode tileMode = TileMode.clamp,
    AlignmentGeometry? focal,
    double focalRadius = 0.0,
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
    return EasingRadialGradient._(
      center: center,
      radius: radius,
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
      focal: focal,
      focalRadius: focalRadius,
      transform: transform,
    );
  }

  const EasingRadialGradient._({
    required super.center,
    required super.radius,
    required List<Color> easedColors,
    required List<double> easedStops,
    required this.sourceColors,
    required this.sourceStops,
    required this.curve,
    required this.transitionCurves,
    required this.colorSpace,
    required this.samplesPerTransition,
    required super.tileMode,
    required super.focal,
    required super.focalRadius,
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
      other is EasingRadialGradient &&
          other.center == center &&
          other.radius == radius &&
          other.tileMode == tileMode &&
          other.focal == focal &&
          other.focalRadius == focalRadius &&
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
    radius,
    tileMode,
    focal,
    focalRadius,
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
      'EasingRadialGradient(center: $center, radius: $radius, '
      'sourceColors: $sourceColors, sourceStops: $sourceStops, curve: $curve, '
      'transitionCurves: $transitionCurves, colorSpace: ${colorSpace.name}, '
      'samplesPerTransition: $samplesPerTransition, tileMode: $tileMode, '
      'focal: $focal, focalRadius: $focalRadius, transform: $transform, '
      'generatedStops: ${colors.length})';
}
