## 0.1.0 - 2026-08-30

Compatibility: Flutter 3.47.1 or newer, including Dart 3.13.1 or newer. The framework API exists in earlier Flutter releases, but 3.47.1 is the first stable SDK matching the Dart constraint.

- Added `EasingLinearGradient`, `EasingRadialGradient` and `EasingSweepGradient` as drop-in Flutter gradient subclasses.
- Added the low-level `easeColorStops` sampler with global and per-transition curves.
- Added dependency-free sRGB, linear RGB, OKLab, OKLCH and HSL interpolation.
- Added premultiplied-alpha mixing and wide-gamut input normalization.
- Added `StepsCurve` with all CSS step positions and exact hard stop generation.
- Added accuracy regression tests against an exact 2,048-point CPU reference.
- Added an interactive example app with comparison, edge fade, playground and Accuracy Lab views.
- Added reproducible profile-mode construction and frame-performance benchmarks.
- Added comprehensive API, architecture, and benchmark documentation.
- Released the package under the BSD 3-Clause License.
