import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'color_space.dart';
import 'eased_color_stops.dart';

/// A [LinearGradient] whose color transitions follow easing curves.
///
/// The factory synchronously converts compact source colors into immutable,
/// densely sampled [colors] and [stops]. [createShader] is inherited unchanged,
/// so retained instances paint through Flutter's native linear-gradient path
/// with no per-frame curve or color-space calculation.
///
/// ```dart
/// DecoratedBox(
///   decoration: BoxDecoration(
///     gradient: EasingLinearGradient(
///       begin: Alignment.topCenter,
///       end: Alignment.bottomCenter,
///       colors: const [Colors.transparent, Colors.black],
///       curve: Curves.easeOutCubic,
///     ),
///   ),
/// )
/// ```
///
/// [begin], [end], [tileMode], and [transform] have exactly the semantics of
/// [LinearGradient], including [AlignmentDirectional] resolution by the
/// `TextDirection` passed to [createShader]. Source lists are defensively copied:
/// [sourceColors] and [sourceStops] preserve the compact input, while inherited
/// [colors] and [stops] expose the generated shader data.
///
/// Inherited operations such as [scale], [withOpacity], [fromColor], and
/// interpolation return a plain [LinearGradient]. They preserve generated stop
/// data and therefore the rendered easing, but discard this class's source and
/// easing metadata.
class EasingLinearGradient extends LinearGradient {
  /// Creates and samples an eased linear gradient.
  ///
  /// Entry `i` of [transitionCurves] controls the transition from `colors[i]`
  /// to `colors[i + 1]`; a null entry uses [curve]. Debug-mode input
  /// preconditions, stop normalization, output-count exceptions, and sampling
  /// complexity are documented by [easeColorStops]. This is a factory, not a
  /// const constructor, because it performs that sampling immediately.
  factory EasingLinearGradient({
    AlignmentGeometry begin = Alignment.centerLeft,
    AlignmentGeometry end = Alignment.centerRight,
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
    return EasingLinearGradient._(
      begin: begin,
      end: end,
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

  const EasingLinearGradient._({
    required super.begin,
    required super.end,
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
      other is EasingLinearGradient &&
          other.begin == begin &&
          other.end == end &&
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
    begin,
    end,
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
      'EasingLinearGradient(begin: $begin, end: $end, '
      'sourceColors: $sourceColors, sourceStops: $sourceStops, curve: $curve, '
      'transitionCurves: $transitionCurves, colorSpace: ${colorSpace.name}, '
      'samplesPerTransition: $samplesPerTransition, tileMode: $tileMode, '
      'transform: $transform, generatedStops: ${colors.length})';
}
