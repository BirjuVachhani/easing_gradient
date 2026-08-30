# easing_gradient

Silky smooth, dependency-free Flutter gradients shaped by any `Curve`.

Flutter's native gradients interpolate colors linearly. That is fast, but it makes the beginning and end of a fade visibly hard, especially on the dark scrims behind text. `easing_gradient` precomputes a small set of intermediate stops that trace an easing curve, then hands those stops back to Flutter's native gradient shader.

## Contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Public API](#public-api)
- [Low-level API](#low-level-api)
- [Per-transition curves](#per-transition-curves)
- [Color spaces](#color-spaces)
- [Hard bands](#hard-bands-with-stepscurve)
- [Accuracy and performance](#accuracy-and-performance)
- [Animation and inherited fields](#animation-and-inherited-fields)
- [Maintainer documentation](#maintainer-documentation)

## Installation

Add the package and import its public library:

```yaml
dependencies:
  easing_gradient: ^0.1.0
```

```dart
import 'package:easing_gradient/easing_gradient.dart';
```

Version 0.1.0 requires Flutter 3.47.1 or newer, which includes Dart 3.13.1. Although the floating-point `Color` API used by the package appeared earlier, Flutter 3.47.1 is the first stable SDK matching the package's Dart constraint.

The package uses Flutter's cross-platform painting APIs and supports Android, iOS, web, macOS, Windows, and Linux wherever Flutter's corresponding native gradient shaders are available.

## Quick start

Replace `LinearGradient` with `EasingLinearGradient`:

```dart
Container(
  decoration: BoxDecoration(
    gradient: EasingLinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Colors.transparent, Colors.black],
    ),
  ),
)
```

The default curve is `Curves.easeInOut`, exactly the cubic bezier used by the original React Native implementation. The default color space is OKLab, which produces visually even, vivid transitions.

Radial and sweep gradients have the same API:

```dart
final glow = EasingRadialGradient(
  colors: const [Colors.white, Colors.transparent],
  curve: Curves.easeOutCubic,
);

final wheel = EasingSweepGradient(
  colors: const [Colors.red, Colors.blue, Colors.red],
  colorSpace: EasingColorSpace.oklch,
);
```

All standard geometry, tiling, focal, angle and transform parameters pass through unchanged.

## Public API

| API | Purpose |
| --- | --- |
| `EasingLinearGradient` | Drop-in linear gradient with eased color transitions. |
| `EasingRadialGradient` | Drop-in radial and focal-radial gradient. |
| `EasingSweepGradient` | Drop-in sweep gradient with configurable angles. |
| `easeColorStops` | Generate immutable colors and positions for another gradient consumer. |
| `EasedColorStops` | Record type returned by `easeColorStops`. |
| `EasingColorSpace` | Select sRGB, linear RGB, OKLab, OKLCH, or HSL interpolation. |
| `StepsCurve` | CSS-style stepped easing with exact hard gradient stops. |
| `StepPosition` | Select jump-start, jump-end, jump-both, or jump-none behavior. |
| `mixColors` | Low-level premultiplied color interpolation used by the sampler. |
| `defaultSamplesPerTransition` | Default request for 15 interior samples per transition. |

## Low-level API

For `CustomPainter`, `ShaderMask`, chart libraries or any other API that consumes colors and stops:

```dart
final (:colors, :stops) = easeColorStops(
  colors: const [Colors.black, Colors.transparent],
  curve: Curves.easeOutCubic,
  samplesPerTransition: 15,
);

final shader = ui.Gradient.linear(
  const Offset(0, 0),
  const Offset(0, 300),
  colors,
  stops,
);
```

The returned lists are unmodifiable. Two opaque colors with the default 15 interior samples produce 17 entries: 15 interior points plus two endpoints. A fully transparent endpoint can add a zero-width limiting-color stop, so the common opaque-to-transparent case produces 18. Steps, duplicate source positions, and deduplication have their own counts.

## Per-transition curves

A multi-color gradient can use a different curve for every transition. Null entries fall back to the global curve:

```dart
EasingLinearGradient(
  colors: const [Colors.red, Colors.yellow, Colors.blue],
  curve: Curves.easeInOut,
  transitionCurves: const [Curves.easeOut, null],
)
```

`transitionCurves` must contain exactly `colors.length - 1` entries.

## Color spaces

Intermediate colors are computed without dependencies. Non-hue components are alpha-weighted before interpolation, so rectangular-space fades such as white to transparent black remain white as alpha falls. In OKLCH and HSL, hue follows a separate angular path, so a fully transparent chromatic endpoint can still influence hue.

| Space | Best for |
| --- | --- |
| `oklab` | The default. Perceptually even, vivid everyday fades. |
| `oklch` | Direct short-path hue sweeps and saturated rainbow effects. |
| `linearRgb` | Physically correct light mixing and parity with postcss-easing-gradients. |
| `srgb` | Native RGB-coordinate parity for opaque or equal-alpha endpoints. Differing alpha intentionally uses alpha-aware interpolation. |
| `hsl` | Familiar CSS-style hue interpolation. Not perceptually uniform. |

Wide-gamut inputs are converted to sRGB before mixing. Output is sRGB because that is the common denominator accepted by Flutter's native gradient shaders. This conversion is lossy for colors outside sRGB. Intermediate output is independently channel-clipped rather than perceptually gamut-mapped, so highly chromatic paths can lose chroma or shift hue.

## Hard bands with StepsCurve

`StepsCurve` is the CSS `steps()` easing function for Flutter. The sampler emits duplicated stop positions, so the boundaries are exact hard edges rather than tiny ramps:

```dart
EasingLinearGradient(
  colors: const [Colors.black, Colors.white],
  curve: const StepsCurve(5, position: StepPosition.jumpNone),
)
```

All four CSS positions are available: `jumpStart`, `jumpEnd`, `jumpBoth` and `jumpNone`.

## Accuracy and performance

The package deliberately uses sampled native gradients instead of a custom fragment shader.

Sampling happens synchronously every time a factory or `easeColorStops` is called. Painting a retained instance calls the unchanged Flutter `LinearGradient`, `RadialGradient` or `SweepGradient` shader path, so there is no curve evaluation or color conversion per frame. GPU cost is the same as a hand-written gradient with the same number of stops, and Flutter keeps its native gradient dithering, which helps hide banding on large dark fades. Cache or hoist stable gradients when creating many of them in frequently rebuilt code.

Automated tests compare the sampled result against an exact 2,049-position CPU reference using Flutter's native straight-RGBA stop interpolation, then compare the premultiplied visible output. Fully transparent endpoints receive a zero-width limiting-color stop before the caller's exact endpoint, preventing hidden RGB from leaking into the final interval. For the recommended defaults (`Curves.easeInOut`, OKLab, 15 extra stops), worst visible channel error stays below one 8-bit color step on a demanding color-to-transparent fade. sRGB and linear RGB do too.

There is no honest universal bound for every input. Polar spaces (OKLCH and HSL), out-of-gamut colors and sharply overshooting curves introduce clipping between samples. Raise `samplesPerTransition` to 31 or 63 when using `Curves.easeInOutQuint`, elastic/back curves or highly saturated OKLCH paths. The example app's Accuracy Lab draws the sampled result, an exact per-column CPU reference and an amplified difference strip so the tradeoff is directly visible.

A CPU color lookup texture was rejected because it loses native dithering and needs image lifecycle management. An analytic fragment shader was rejected because it cannot support arbitrary Dart `Curve` implementations, adds per-pixel math, needs async asset precaching and requires backend-specific testing. Both add more complexity for worse practical tradeoffs on the normal path.

Reproduce the device benchmark from the example directory:

```sh
cd example
flutter drive --profile \
  -d <physical-device-id> \
  --target integration_test/gradient_performance_test.dart \
  --driver test_driver/performance_driver.dart
```

The harness writes raw JSON to `example/build/performance/gradient_benchmark.json`. See [the benchmark report](doc/benchmarks/gradient-performance.md) for workload details, metrics, limitations, and recorded results.

## Animation and inherited fields

The inherited `colors` and `stops` fields contain the generated dense lists. The compact inputs are available as `sourceColors` and `sourceStops`.

Inherited operations such as `withOpacity`, `scale` and gradient interpolation return Flutter's base gradient type. They preserve the generated stops, so the eased appearance remains. Interpolating gradients containing duplicated `StepsCurve` stops can soften a hard edge during the middle of the animation because Flutter merges duplicate positions when it builds the union of both stop lists.

## Maintainer documentation

- [Codebase architecture and invariants](doc/architecture.md)
- [Profile benchmark methodology and results](doc/benchmarks/gradient-performance.md)

## Credits

This is a Flutter port and expansion of:

- [Easing Gradients](https://larsenwork.com/easing-gradients/) by Andreas Larsen
- [postcss-easing-gradients](https://github.com/larsenwork/postcss-easing-gradients)
- [react-native-easing-gradient](https://github.com/phamfoo/react-native-easing-gradient)
- [CSSWG issue 1332](https://github.com/w3c/csswg-drafts/issues/1332)
- [OKLab](https://bottosson.github.io/posts/oklab/) by Bjorn Ottosson

Released under the [BSD 3-Clause License](LICENSE). Upstream inspirations and their MIT notices are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
