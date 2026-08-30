# easing_gradient: Flutter port of easing gradients

## Context

Flutter's built-in gradients interpolate linearly between stops, which produces visible hard edges, worst on color-to-transparent scrims. The fix (from larsenwork.com/easing-gradients, react-native-easing-gradient, and CSSWG issue #1332) is to precompute many intermediate color stops that trace an easing curve ("low poly" easing), then let the native gradient shader interpolate between adjacent sampled stops. CPU cost is a one-time sampling at construction; GPU cost equals any multi-stop gradient. This document records the original design decisions. The implementation is now complete; current behavior and invariants are documented in `doc/architecture.md`.

Verified against the local SDK (Flutter 3.47.1 at `~/.puro/envs/default/flutter`):

- `Curves.easeInOut == Cubic(0.42, 0, 0.58, 1)`, exactly the RN library's default easing.
- `Curve.transform(t)` asserts `t` in [0,1], returns t unchanged at exactly 0 and 1; outputs may overshoot [0,1] (elastic/back curves).
- `LinearGradient`/`RadialGradient`/`SweepGradient` have const generative constructors with `required super.colors, super.stops`; a subclass with a public factory + private const generative constructor is valid, and inherited `createShader`, `==`, and `lerp` (union-of-stops resampling) all work with dense stop lists.
- The floating-point Color API appeared in Flutter 3.27; the effective release minimum is Flutter 3.47.1 because the package requires Dart 3.13.1.

User decisions: default color space = **OKLab**; include **example app** and **StepsCurve**; rendering = **sampled stops only, with an Accuracy Lab in the example app that proves it** (no exact-renderer implementation in v1).

## Rendering strategy analysis (explored, decision recorded)

Three ways to render an eased gradient were evaluated for accuracy and performance:

1. **Sampled stops into the native gradient shader (CHOSEN).** Precompute N stops per transition; the GPU lerps between adjacent stops. Accuracy: piecewise-linear error is bounded by h^2 * max|f''| / 8 with h = 1/(samples+1); for standard curves (easeInOut family) at the default 15 samples this is below 1/255, i.e. smaller than one 8-bit quantization step, so it is more accurate than the screen can display. Sharper curves (easeInOutQuint knees, elastic) may reach a few LSB: the fix is raising samplesPerTransition (documented), not a new renderer. Performance: best in class (native gradient shader, Skia batching, zero per-frame CPU). Bonus: native gradients get automatic dithering, which hides banding on large dark scrims.
2. **CPU-baked color LUT + ImageShader (rejected for v1).** Bake ~512 exact texels (any curve, any color space) via a synchronous `Picture.toImageSync`, render with `ImageShader` (verified: both `ImageShader` and `FragmentShader` extend `ui.Shader`, so either could be returned from a painting `Gradient.createShader`). Mathematically exact, roughly native-gradient per-pixel cost, but: loses gradient dithering (real banding risk on large fades), needs `ui.Image` lifecycle management, and only covers linear geometry without a fragment shader.
3. **Analytic fragment shader (rejected for v1).** Exact per-pixel bezier inversion + OKLab mixing in a bundled .frag asset. Exact for representable curves only (Cubic/steps, not arbitrary Dart Curves), heaviest per-pixel ALU, requires async `FragmentProgram.fromAsset` precache, shader asset bundling, and Impeller/Skia dialect testing.

Decision: ship strategy 1; prove its sufficiency empirically with an **Accuracy Lab** page in the example app (side-by-side sampled vs exact per-pixel CPU reference with an amplified-difference view and a sample-count slider). Summarize this analysis in the README so users understand why there is no "exact mode".

## File layout

```
lib/
├── easing_gradient.dart              # barrel: exports only
└── src/
    ├── color_space.dart              # EasingColorSpace enum + conversion/mix math
    ├── eased_color_stops.dart        # low-level sampler: easeColorStops()
    ├── steps_curve.dart              # StepsCurve + StepPosition (CSS steps() analog)
    ├── easing_linear_gradient.dart
    ├── easing_radial_gradient.dart
    └── easing_sweep_gradient.dart
test/
├── color_space_test.dart
├── eased_color_stops_test.dart
├── steps_curve_test.dart
├── easing_gradient_test.dart
└── approximation_accuracy_test.dart
example/                              # runnable companion app, depends on path: ../
└── lib/ (main.dart, comparison_page.dart, benchmark/gradient_benchmark.dart)
```

The placeholder scaffold class and test were removed during implementation.

## Public API

### Low-level sampler (`src/eased_color_stops.dart`)

```dart
typedef EasedColorStops = ({List<Color> colors, List<double> stops});

EasedColorStops easeColorStops({
  required List<Color> colors,
  List<double>? stops,                       // null => uniform, like Gradient
  Curve curve = Curves.easeInOut,
  List<Curve?>? transitionCurves,            // length colors.length - 1; null entry => fall back to curve
  EasingColorSpace colorSpace = EasingColorSpace.oklab,
  int samplesPerTransition = 15,             // postcss parity; denom 16 samples t=0.5 exactly
});
```

Returned lists are `List.unmodifiable`. Record typedef (destructurable, zero API surface) instead of a result class.

### Gradient subclasses

Pattern (identical for all three; radial adds `center/radius/focal/focalRadius`, sweep adds `center/startAngle/endAngle`):

```dart
class EasingLinearGradient extends LinearGradient {
  factory EasingLinearGradient({
    AlignmentGeometry begin = Alignment.centerLeft,
    AlignmentGeometry end = Alignment.centerRight,
    required List<Color> colors,
    List<double>? stops,
    Curve curve = Curves.easeInOut,
    List<Curve?>? transitionCurves,
    EasingColorSpace colorSpace = EasingColorSpace.oklab,
    int samplesPerTransition = 15,
    TileMode tileMode = TileMode.clamp,
    GradientTransform? transform,
  });  // runs easeColorStops once, delegates to a private const generative
       // constructor that passes eased lists to super(colors:, stops:)

  final List<Color> sourceColors;       // originals; inherited colors/stops are the dense lists
  final List<double>? sourceStops;
  final Curve curve;
  final List<Curve?>? transitionCurves;
  final EasingColorSpace colorSpace;
  final int samplesPerTransition;
  // toString, equality, and hashCode include source easing configuration.
}
```

Inherited `lerp/scale/withOpacity` return plain base-class instances built from dense lists (eased look preserved; document the type downgrade). Caveat to document: lerp's `SplayTreeSet` union collapses duplicated stop positions, so StepsCurve hard edges soften slightly mid-lerp.

### StepsCurve (`src/steps_curve.dart`)

```dart
enum StepPosition { jumpStart, jumpEnd, jumpBoth, jumpNone }

class StepsCurve extends Curve {
  const StepsCurve(this.count, {this.position = StepPosition.jumpEnd});
  // transformInternal per CSS Easing spec: i = (t*n).floor();
  // jumpEnd: i/n; jumpStart: (i+1)/n clamped; jumpBoth: (i+1)/(n+1);
  // jumpNone: i/(n-1) clamped (assert count >= 2 for jumpNone, with message)
}
```

Usable as a normal `Curve` anywhere; the sampler special-cases it for exact bands.

## Sampling algorithm

1. **Validation** (all asserts carry messages explaining the invariant): `colors.length >= 2`; `stops` null or same length as colors; `transitionCurves` null or length `colors.length - 1`; `samplesPerTransition >= 1`.
2. **Stop normalization**: null stops => uniform `i / (n-1)`. Otherwise clamp to [0,1] and force monotonic non-decreasing (`s[i] = max(s[i], s[i-1])`), in release mode too. First stop > 0 / last < 1 kept as-is (renderer clamps under TileMode.clamp).
3. **Main loop** per transition `i` over `[start, end]`, colors `c0, c1`, `activeCurve = transitionCurves?[i] ?? curve`:
   - `end - start <= 0` (user hard edge): emit `(start, c0)`, `(start, c1)`.
   - `activeCurve is StepsCurve`: exact-band branch below; `samplesPerTransition` ignored.
   - Else for `step in 0..denom` where `denom = samplesPerTransition + 1`: `progress = step / denom` (division so final progress is exactly 1.0, satisfying Curve.transform's assert), `f = activeCurve.transform(progress)`, emit `(start + (end-start)*progress, mix(c0, c1, f, colorSpace))`.
   - `emit(stop, color)` dedups only when BOTH position and color equal the last emitted pair (removes the shared boundary sample between transitions, never merges intentional hard edges).
4. **Steps branch**: compute plateau values `v_0..v_k` and jump positions from the position formula; emit `(start, mix(c0,c1,v_0))`, then per jump at location `loc`: `(loc, mix(..v_prev))` and `(loc, mix(..v_next))` (same position, different color = hard stop, valid in Skia and Impeller), then `(end, mix(c0,c1,v_k))`.
5. `mix` short-circuits `f == 0 => c0`, `f == 1 => c1` so endpoints are bit-exact.

Output size: `(colors.length - 1) * (samplesPerTransition + 1) + 1` stops (17 for 2 colors by default).

## Color math (`src/color_space.dart`)

```dart
enum EasingColorSpace { srgb, linearRgb, oklab, oklch, hsl }
```

- **Input normalization**: non-sRGB inputs (e.g. displayP3) converted via `color.withValues(colorSpace: ColorSpace.sRGB)` first; outputs built with `Color.from(...)` in sRGB.
- **sRGB transfer** (per channel, sign-mirrored so extrapolation behaves): linearize `|u|<=0.04045 ? u/12.92 : sign(u)*pow((|u|+0.055)/1.055, 2.4)`; delinearize is the inverse with threshold 0.0031308.
- **OKLab**: Ottosson's reference matrices (linear sRGB -> LMS -> cbrt -> Lab, and the inverse). OKLCH derived via `C = sqrt(a^2+b^2)`, `h = atan2(b, a)`.
- **HSL**: standard max/min formulas.
- **Hue interpolation** (oklch, hsl): shorter arc, `dh` normalized into `(-pi, pi]`. Powerless-hue rule: if an endpoint is achromatic (C or S < 1e-7), use the other endpoint's hue (CSS Color 4 behavior).
- **Premultiplied alpha, always on**: convert both endpoints to the mixing space; premultiply non-hue components by alpha; lerp components and alpha by `f` (extrapolating when f is outside [0,1]); unpremultiply when `a > 1e-7` else fall back to straight-interpolated components; convert back to sRGB; clamp every channel and alpha to [0,1] at the very end. This is what keeps white->transparent white instead of gray.
- **Overshoot policy**: never clamp `f` (preserves elastic/back character); clamp only final sRGB channels.
- Converters are private top-level functions marked `@visibleForTesting` where tests need them.

## Tests

- `color_space_test.dart`: sRGB transfer round trip (incl. threshold values); OKLab reference values (white/red/green/blue from Ottosson's table, tol 1e-3); sRGB<->OKLab/OKLCH round trips (tol 1e-6); HSL round trip; hue shorter-arc (350deg to 10deg passes 0deg); powerless hue (gray to red stays on the gray-red line).
- `eased_color_stops_test.dart`: stops monotonic in [0,1] across curves/spaces/counts; endpoints bit-exact; count formula holds; `Curves.linear` + srgb + opaque colors reproduces `Color.lerp`; easeInOut midpoint = exact 50% mix; per-transition override; custom stops [0, 0.3, 1] boundary appears once; white->transparent stays white (r=g=b=1 within 1e-6) in linearRgb and oklab; elasticOut overshoots between grays yet stays in [0,1]; zero-width transition emits the two-stop hard edge; descending stops normalized; all asserts fire.
- `steps_curve_test.dart`: transform matches CSS steps() for all four positions; sampler emits duplicated positions, band count == count.
- `easing_gradient_test.dart`: `is LinearGradient`/`is Gradient` for all three; `createShader(rect)` returns a Shader; all pass-through params preserved; dense counts + `sourceColors` correct; equality semantics; `LinearGradient.lerp` between two eased gradients non-null and endpoint-faithful; `withOpacity` preserves eased stops; renders inside `pumpWidget(DecoratedBox(...))` without exceptions.
- `approximation_accuracy_test.dart`: the Accuracy Lab claim as an automated regression. For each of several curves (easeInOut, easeInOutCubic, easeInOutQuint, easeOutBack) and color spaces, walk 2048 positions across the gradient, compute the exact value `mix(c0, c1, curve.transform(t), space)` and the piecewise-linear value the shader would produce from the sampled stops (lerp between the bracketing stops in sRGB, matching what the GPU does), and assert the max per-channel error at the default 15 samples is under 1/255 for the standard curves. Also assert the error decreases monotonically as `samplesPerTransition` grows (16, 32, 64), and record (via a printed table, not an assertion) the error for deliberately sharp curves such as `Curves.elasticOut` so the README's "raise samplesPerTransition for extreme curves" guidance stays honest.

## Example app

- `comparison_page.dart`: scrim use case, side-by-side plain `LinearGradient([black, transparent])` vs `EasingLinearGradient` over an image with text.
- `playground_page.dart`: live preview (linear/radial/sweep selectable), curve dropdown (linear, easeInOut, easeInOutCubic, easeInOutQuint, elasticOut, StepsCurve(5)), color-space dropdown, `samplesPerTransition` slider (1..32) to visualize low-poly convergence.
- `accuracy_lab_page.dart`: proves sampled stops match the true curve. Renders three strips: (1) the sampled `EasingLinearGradient`, (2) an exact per-pixel CPU reference (a `CustomPainter` that, for each device-pixel column x, computes `mix(c0, c1, curve.transform(x/width), colorSpace)` exactly and draws a 1px line; cached into a picture and only recomputed on config change), (3) an amplified difference view (per-column `|sampled - exact|` scaled by an amplification slider, e.g. 1x/8x/32x/128x, drawn as a heat strip) plus a max-error readout in 1/255 units. Controls: curve dropdown (including the sharp ones: easeInOutQuint, elasticOut), color-space dropdown, `samplesPerTransition` slider so the error can be watched collapsing below one 8-bit step.
- `gradient_compare.dart`: reusable side-by-side widget + optional stop-tick debug overlay.

## Docs and pubspec

- README: problem statement with before/after, how it works, quick start (drop-in + scrim), low-level `easeColorStops` with CustomPainter, color-space table (srgb: Color.lerp parity; linearRgb: postcss parity; oklab: default, perceptual; oklch/hsl: hue paths), StepsCurve, notes (premultiplied alpha, dense `colors`/`stops` vs `sourceColors`, lerp behavior, overshoot), a short "Accuracy and performance" section summarizing the rendering strategy analysis (why sampled stops, error bound, dithering advantage, when to raise `samplesPerTransition`, pointer to the example's Accuracy Lab), credits (react-native-easing-gradient MIT, postcss-easing-gradients, Ottosson OKLab).
- Style rules everywhere (docs, dartdoc, comments): no em-dashes; every assert has a message explaining the invariant.
- pubspec: real description, `version: 0.1.0`, `topics: [gradient, easing, color, ui, animation]`, `flutter: ">=3.47.1"`; remove template boilerplate comments; BSD 3-Clause LICENSE text with third-party notices; CHANGELOG 0.1.0.

## Implementation order

0. Copy this plan into the repo at `docs/plans/easing-gradient.md` so it lives with the code and can be updated as implementation proceeds.
1. Housekeeping: pubspec, LICENSE, delete placeholders, barrel skeleton.
2. `src/color_space.dart` + its tests (pure math first).
3. `src/steps_curve.dart` + tests.
4. `src/eased_color_stops.dart` (validation, loop, steps branch, dedup) + tests; get this green before gradients.
5. Three gradient subclasses + tests.
6. `approximation_accuracy_test.dart`: locks in the accuracy claim before it is written into the docs.
7. Dartdoc pass, README (including the accuracy and performance section), CHANGELOG.
8. Example app, Accuracy Lab page last (it reuses the exact-reference math from step 6).
9. `dart format .`, `flutter analyze`, `flutter test`, `dart pub publish --dry-run`.

## Verification

- `flutter test` green across all five test files, including the accuracy regression.
- `flutter analyze` clean with flutter_lints.
- Run the example app (`cd example && flutter run`) and visually confirm: the eased scrim has no hard edge where the plain one does; playground curves/spaces/samples behave; StepsCurve shows hard bands; the Accuracy Lab difference strip is black at 1x and stays visually flat until amplification is cranked well past 32x for standard curves.
- `dart pub publish --dry-run` passes validation.
