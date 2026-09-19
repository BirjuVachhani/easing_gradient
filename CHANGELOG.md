## 0.2.0 - 2026-09-19

Compatibility is unchanged from 0.1.0: Flutter 3.47.1 or newer, including Dart 3.13.1 or newer.

- Added an optional `outputColorSpace` to `mixColors`, `easeColorStops` and the three gradient factories, selecting Display P3 or extended sRGB output independently of the interpolation space. Output stays bounded sRGB by default, so existing code is unaffected.
- Kept wide-gamut input in extended-sRGB working coordinates through mixing and converted to the chosen output primaries before any bounded-gamut clipping, so opting in converts colors rather than relabelling them. Alpha stays bounded in every output space.
- Documented that HSL keeps a bounded sRGB working space for CSS parity, so choosing a wide-gamut output does not make HSL interpolation gamut-preserving.
- Documented backend precision limits and separated approximation-error measurements from visible banding claims.
- Rebuilt the example as a website: sticky top nav with addressable per-page URLs, centered content column, dark and light themes, bundled Geist typography, and demos laid out beside their controls.
- Added a landing page built around a photo card whose caption scrim is masked by a live, adjustable easing curve, alongside side-by-side native and eased comparisons.
- Added a documentation page, and moved the gradient galleries behind their own destinations.
- Added an Examples page recreating reference website gradients, two palette boards, and all 177 pluto background gradients, each opening its source and color palette in a dialog.
- Added syntax-highlighted, copyable code blocks throughout the example site.
- Added iPhone 17 Pro device frames around the edge-fade list and paragraph examples using `device_preview`, with soft edges sized from the status bar and home indicator.
- Corrected Accuracy Lab alpha/compositing diagnostics and physical-pixel reference rendering.
- Added example-only bounded adaptive and Bézier-parameter sampling comparisons and a reproducible sampling benchmark.
- Added an example-only cubic alpha-mask shader with controllable alpha dithering and a zero-noise control.

## 0.1.0 - 2026-08-30

Compatibility: Flutter 3.47.1 or newer, including Dart 3.13.1 or newer. The framework API exists in earlier Flutter releases, but 3.47.1 is the first stable SDK matching the Dart constraint.

- Added `EasingLinearGradient`, `EasingRadialGradient` and `EasingSweepGradient` as drop-in Flutter gradient subclasses.
- Added the low-level `easeColorStops` sampler with global and per-transition curves.
- Added dependency-free sRGB, linear RGB, OKLab, OKLCH and HSL interpolation.
- Added premultiplied-alpha mixing and wide-gamut input normalization.
- Added `StepsCurve` with all CSS step positions and exact hard stop generation.
- Added accuracy regression tests against a 2,049-position CPU interpolation model.
- Added an interactive example app with comparison, edge fade, playground and Accuracy Lab views.
- Added reproducible profile-mode construction and frame-performance benchmarks.
- Added comprehensive API, architecture, and benchmark documentation.
- Released the package under the BSD 3-Clause License.
