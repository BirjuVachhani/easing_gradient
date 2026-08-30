/// Smooth, dependency-free Flutter gradients shaped by easing curves.
///
/// Use [EasingLinearGradient], [EasingRadialGradient], or
/// [EasingSweepGradient] anywhere a Flutter painting [Gradient] is accepted:
///
/// ```dart
/// DecoratedBox(
///   decoration: BoxDecoration(
///     gradient: EasingLinearGradient(
///       colors: const [Colors.transparent, Colors.black],
///       curve: Curves.easeInOut,
///     ),
///   ),
/// )
/// ```
///
/// Use [easeColorStops] when another API wants parallel color and position
/// lists instead of a painting gradient:
///
/// ```dart
/// final (:colors, :stops) = easeColorStops(
///   colors: const [Colors.red, Colors.blue],
/// );
/// ```
///
/// Easing is approximated at construction time by generated stops. Flutter's
/// native gradient shader linearly interpolates between those stops; the shader
/// does not evaluate the [Curve]. Choose [EasingColorSpace] for the color path,
/// [StepsCurve] for hard bands, `transitionCurves` for per-segment shaping, and
/// `samplesPerTransition` when a sharp path needs more fidelity.
library;

export 'src/color_space.dart' show EasingColorSpace, mixColors;
export 'src/eased_color_stops.dart'
    show EasedColorStops, defaultSamplesPerTransition, easeColorStops;
export 'src/easing_linear_gradient.dart' show EasingLinearGradient;
export 'src/easing_radial_gradient.dart' show EasingRadialGradient;
export 'src/easing_sweep_gradient.dart' show EasingSweepGradient;
export 'src/steps_curve.dart' show StepPosition, StepsCurve;
