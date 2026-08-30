# easing_gradient example

An interactive companion app for the [`easing_gradient`](https://github.com/BirjuVachhani/easing_gradient) Flutter package.

## What it demonstrates

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

A native sampled gradient beside a direct per-column CPU reference and an amplified premultiplied-channel difference view.

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
