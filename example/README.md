# easing_gradient example

An interactive companion site for the [`easing_gradient`](https://github.com/BirjuVachhani/easing_gradient) Flutter package.

It is built as a website rather than a phone app: a sticky top nav, a centered content column capped at 1240 logical pixels, a dark and light theme toggle, and bundled Geist typography. Demos sit beside their controls on wide viewports and stack below the 900-pixel breakpoint, where the nav links collapse into a menu.

## What it demonstrates

### Home

A landing page: the package promise, an install command, one focused native-versus-eased scrim comparison, and short feature blocks. It links into the docs and the full galleries rather than repeating them.

### Docs

Package documentation with a sticky section rail, scroll spy, and a compact contents sheet. Sections cover installation, the gradient classes, the low-level sampler, per-transition curves, hard bands, color spaces, wide-gamut output, transparency, accuracy, performance, animation, and limitations.

### Examples

Recreations of gradients worth stealing: full-bleed website backgrounds, two palette boards of capsule swatches, and all 177 background gradients from the [pluto](https://github.com/BirjuVachhani/pluto) new-tab project, each rebuilt with `EasingLinearGradient`.

### Compare

A responsive gallery of 18 fixed comparisons covering:

- native versus eased scrims;
- ease-in, ease-out, and ease-in-out pacing;
- sRGB, linear RGB, OKLab, OKLCH, and HSL interpolation;
- premultiplied transparency over a checkerboard;
- multi-stop palettes, custom source positions, and per-transition curves;
- all four `StepsCurve` positions;
- linear, radial, focal-radial, and sweep geometry;
- coarse, default, and high sample densities.

### Playground

Interactive controls for gradient geometry, curve, color space, and interior sample count.

### Accuracy Lab

Compare uniform, dense uniform, Bézier-parameter, and bounded error-driven stop placement at matched sample budgets. Presets include black/white fades, a shallow gray ramp, and chromatic paths. The CPU reference uses nonoverlapping physical-pixel columns. Error includes alpha and composited colors, but is a mathematical model, not measured monitor output.

### Edge fade

Two mobile examples inside an iPhone 17 Pro frame from `device_preview`: a compact list and a long-form paragraph reader. The frame supplies the real screen shape, safe areas, Dynamic Island, and home indicator around an ordinary widget tree. Native alpha masks have a sample-count control and black/white backgrounds. Enable **Show alpha-dithering experiment** for two example-only analytic cubic masks: no noise and stationary alpha noise. Compare these two shader controls to isolate dithering; both use one mask layer, unlike the original two-mask recipe. Noise is adjustable from 0 to 4 peak-to-peak alpha units out of 255. This does not establish that banding is fixed on any particular display.

## Run the app

From this directory:

```sh
flutter pub get
flutter run -d chrome
```

Replace `chrome` with any configured iOS, Android, or web target.

## Run tests

```sh
flutter analyze
flutter test
```

The widget tests cover navigation, lazy catalog completeness, and narrow/wide responsive layouts.

## Run the profile benchmark

Use a physical device for meaningful frame timing:

```sh
flutter drive --profile \
  -d <physical-device-id> \
  --target integration_test/gradient_performance_test.dart \
  --driver test_driver/performance_driver.dart
```

The generated raw result is written to `build/performance/gradient_benchmark.json`. Benchmark methodology and a recorded iOS run are documented in [`../doc/benchmarks/gradient-performance.md`](../doc/benchmarks/gradient-performance.md).

## Sampling experiment

```sh
flutter test test/sampling_benchmark_test.dart --dart-define=SAMPLING_BENCHMARK=true
```

Writes `build/performance/sampling.json`. It records actual stop counts, construction timings, and densely evaluated model errors. Timings under `flutter test` are diagnostic host/debug timings, not production frame performance. Bézier placement falls back for unsupported curves; adaptive probes have a fixed budget and can miss arbitrary narrow features. Neither strategy guarantees freedom from display quantization bands.

For the external-monitor report, compare the same window size and content on both displays. Record the target (Chrome or native), Flutter/backend version, DPR, exact preset, native stop count, noise amplitude, display profile, and HDR/SDR settings. Do not change display settings automatically. Image previews and screenshots introduce their own rendering and color-management paths.
