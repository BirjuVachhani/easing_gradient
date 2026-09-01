# easing_gradient

Silky smooth, dependency-free Flutter gradients shaped by any `Curve`.

Flutter's native gradients interpolate colors linearly. That is fast, but it makes the beginning and end of a fade visibly hard, especially on the dark scrims behind text. `easing_gradient` precomputes a small set of intermediate stops that trace an easing curve, then hands those stops back to Flutter's native gradient shader.

| Flutter `LinearGradient` | `EasingLinearGradient` |
| :---: | :---: |
| ![A transparent-to-black scrim over a colorful backdrop, with a visible horizontal seam where the overlay begins](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/scrim-native.png) | ![The same scrim eased with Curves.easeInOut, fading in with no visible beginning](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/scrim-eased.png) |

Both pictures put the same `Colors.transparent` to `Colors.black` overlay across the bottom 58 percent of the same backdrop. On the left, the straight alpha ramp changes slope the moment it starts, and the eye reads that corner as a line drawn across the image. On the right, `Curves.easeInOut` eases into the ramp, so the overlay has no visible beginning.

## Contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Public API](#public-api)
- [Low-level API](#low-level-api)
- [Per-transition curves](#per-transition-curves)
- [Color spaces](#color-spaces)
- [Hard bands](#hard-bands-with-stepscurve)
- [Edge fade](#edge-fade)
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

| One curve everywhere | A curve per transition |
| :---: | :---: |
| ![A four-color gradient with every transition eased by the same curve](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/transitions-global.webp) | ![The same four colors with easeOutCubic, the global curve, and easeInCubic on the three transitions](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/transitions-per-segment.webp) |

## Color spaces

Intermediate colors are computed without dependencies. Non-hue components are alpha-weighted before interpolation, so rectangular-space fades such as white to transparent black remain white as alpha falls. In OKLCH and HSL, hue follows a separate angular path, so a fully transparent chromatic endpoint can still influence hue.

Every preview below runs the same blue to yellow fade with `Curves.linear`, so only the route between the endpoints changes.

| Space | Preview | Best for |
| --- | --- | --- |
| `oklab` | ![Blue to yellow through a muted neutral midpoint](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/space-oklab.webp) | The default. Perceptually even, vivid everyday fades. |
| `oklch` | ![Blue to yellow sweeping through cyan and green](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/space-oklch.webp) | Direct short-path hue sweeps and saturated rainbow effects. |
| `linearRgb` | ![Blue to yellow with a brighter, lighter midpoint](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/space-linear-rgb.webp) | Physically correct light mixing and parity with postcss-easing-gradients. |
| `srgb` | ![Blue to yellow through a darker gray midpoint](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/space-srgb.webp) | Native RGB-coordinate parity for opaque or equal-alpha endpoints. Differing alpha intentionally uses alpha-aware interpolation. |
| `hsl` | ![Blue to yellow sweeping through saturated cyan and green](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/space-hsl.webp) | Familiar CSS-style hue interpolation. Not perceptually uniform. |

Wide-gamut inputs are converted to sRGB before mixing. Output is sRGB because that is the common denominator accepted by Flutter's native gradient shaders. This conversion is lossy for colors outside sRGB. Intermediate output is independently channel-clipped rather than perceptually gamut-mapped, so highly chromatic paths can lose chroma or shift hue.

## Hard bands with StepsCurve

`StepsCurve` is the CSS `steps()` easing function for Flutter. The sampler emits duplicated stop positions, so the boundaries are exact hard edges rather than tiny ramps:

```dart
EasingLinearGradient(
  colors: const [Colors.black, Colors.white],
  curve: const StepsCurve(5, position: StepPosition.jumpNone),
)
```

All four CSS positions are available. Each preview below runs `StepsCurve(5, position: ...)` from a near-black to orange.

| Position | Preview | Which endpoint colors get a band |
| --- | --- | --- |
| `jumpStart` | ![Five bands, the first already lifted off the start color and the last showing the full end color](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/steps-jump-start.webp) | End only. |
| `jumpEnd` | ![Five bands starting on the start color, the last stopping short of the end color](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/steps-jump-end.webp) | Start only. This is the CSS default and the default here. |
| `jumpBoth` | ![Five bands, neither the start nor the end color among them](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/steps-jump-both.webp) | Neither. |
| `jumpNone` | ![Five bands running from the start color to the end color](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/steps-jump-none.webp) | Both. Usually the best looking choice, and it needs a count of at least 2. |

## Edge fade

A gradient also makes a good alpha mask. Combine `ShaderMask` with `BlendMode.dstIn` and a scrollable's edges dissolve into whatever sits behind them, instead of stopping at a hard viewport edge.

`BlendMode.dstIn` multiplies the child's alpha by the mask's alpha and keeps the child's colors, so only the mask's alpha channel matters and its opaque color is arbitrary. Each edge below is a literal two-color gradient: transparent to opaque at the top, and opaque to transparent at the bottom. Both sides use identical content, colors, geometry, and extents. Only the gradient class differs:

### Black background

| `LinearGradient` mask | `EasingLinearGradient` mask |
| :---: | :---: |
| ![Light paragraphs and text list tiles fading at a constant rate over a black background](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/edge-fade-black-linear.webp) | ![The same light paragraphs and text list tiles fading smoothly over a black background](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/edge-fade-black-eased.webp) |

### White background

| `LinearGradient` mask | `EasingLinearGradient` mask |
| :---: | :---: |
| ![Dark paragraphs and text list tiles fading at a constant rate over a white background](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/edge-fade-white-linear.webp) | ![The same dark paragraphs and text list tiles fading smoothly over a white background](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/edge-fade-white-eased.webp) |

The linear mask holds one constant alpha slope, so it begins hiding paragraph lines immediately at the edge and then stops abruptly where the ramp meets the opaque middle. That corner is the same artifact as the seam in the scrim at the top of this page. The eased mask starts and ends flat instead: paragraphs and list-tile labels stay legible closer to the edge, then fall away, and nothing marks where the fade ends.

All four figures have no tile or paragraph background fills. They render the same text, accent dots, geometry, and 30 percent edge extent directly on black or white. The larger extent spreads each alpha ramp across more paragraph baselines for a smoother transition.

```dart
// Sampled once per build, not once per frame.
final topFade = EasingLinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: const [Colors.transparent, Colors.black],
);
final bottomFade = EasingLinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: const [Colors.black, Colors.transparent],
);

return LayoutBuilder(
  builder: (context, constraints) {
    final height = constraints.maxHeight;
    final top = Rect.fromLTWH(0, 0, constraints.maxWidth, height * 0.30);
    final bottom = Rect.fromLTWH(
      0,
      height * 0.70,
      constraints.maxWidth,
      height * 0.30,
    );
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (_) => topFade.createShader(top),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (_) => bottomFade.createShader(bottom),
        child: ListView.builder(...),
      ),
    );
  },
);
```

Swap `begin` and `end` for `Alignment.centerLeft` and `Alignment.centerRight` to fade a horizontal list.

Build both gradients outside the callbacks and only call `createShader` inside them, as above. `ShaderMask` asks for a shader on every paint, so constructing an easing gradient inside a callback would resample the curve on every frame of a scroll.

The example app's Edge fade tab has a live version with controls for the fade extent and curve, plus a side-by-side comparison against a linear mask.

## Accuracy and performance

The package deliberately uses sampled native gradients instead of a custom fragment shader.

Sampling happens synchronously every time a factory or `easeColorStops` is called. Painting a retained instance calls the unchanged Flutter `LinearGradient`, `RadialGradient` or `SweepGradient` shader path, so there is no curve evaluation or color conversion per frame. GPU cost is the same as a hand-written gradient with the same number of stops, and Flutter keeps its native gradient dithering, which helps hide banding on large dark fades. Cache or hoist stable gradients when creating many of them in frequently rebuilt code.

Automated tests compare the sampled result against an exact 2,049-position CPU reference using Flutter's native straight-RGBA stop interpolation, then compare the premultiplied visible output. Fully transparent endpoints receive a zero-width limiting-color stop before the caller's exact endpoint, preventing hidden RGB from leaking into the final interval. For the recommended defaults (`Curves.easeInOut`, OKLab, 15 extra stops), worst visible channel error stays below one 8-bit color step on a demanding color-to-transparent fade. sRGB and linear RGB do too.

There is no honest universal bound for every input. Polar spaces (OKLCH and HSL), out-of-gamut colors and sharply overshooting curves introduce clipping between samples. Raise `samplesPerTransition` to 31 or 63 when using `Curves.easeInOutQuint`, elastic/back curves or highly saturated OKLCH paths. The example app's Accuracy Lab draws the sampled result, an exact per-column CPU reference and an amplified difference strip so the tradeoff is directly visible.

| `samplesPerTransition: 3` | `samplesPerTransition: 15` |
| :---: | :---: |
| ![A sharply eased fade showing flat facets where straight segments meet](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/density-coarse.webp) | ![The same fade at the default sample count, with no visible facets](https://raw.githubusercontent.com/BirjuVachhani/easing_gradient/main/doc/images/density-default.webp) |

Both strips use `Curves.easeInOutQuint`, whose steep middle is where a piecewise-linear approximation shows up first. Three interior samples leave visible flat facets. The default of fifteen does not.

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

The figures in `doc/images/` are generated, not hand-drawn. Rebuild and losslessly optimize them after any change to sampling, color math, or figure content:

```sh
flutter test tool/generate_readme_images.dart
python3 tool/optimize_readme_images.py
```

The optimizer requires OxiPNG, the WebP command-line tools, and Pillow. It verifies decoded RGBA bytes before replacing a PNG with lossless WebP. The dithered hero scrims remain PNG because they compress better in that format.

## Credits

This is a Flutter port and expansion of:

- [Easing Gradients](https://larsenwork.com/easing-gradients/) by Andreas Larsen
- [postcss-easing-gradients](https://github.com/larsenwork/postcss-easing-gradients)
- [react-native-easing-gradient](https://github.com/phamfoo/react-native-easing-gradient)
- [CSSWG issue 1332](https://github.com/w3c/csswg-drafts/issues/1332)
- [OKLab](https://bottosson.github.io/posts/oklab/) by Bjorn Ottosson

Released under the [BSD 3-Clause License](LICENSE). Upstream inspirations and their MIT notices are listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
