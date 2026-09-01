# Codebase Guide

This guide explains how `easing_gradient` works, where responsibilities live, and which invariants must remain true when the package changes.

## Repository map

| Path | Responsibility |
| --- | --- |
| `lib/easing_gradient.dart` | Public library and exports. |
| `lib/src/eased_color_stops.dart` | Input validation, source-stop normalization, curve sampling, hard bands, transparent endpoint guards, and immutable output. |
| `lib/src/color_space.dart` | Color-space conversion and alpha-aware interpolation. |
| `lib/src/steps_curve.dart` | CSS-style staircase easing and exact hard-band values. |
| `lib/src/easing_*_gradient.dart` | Drop-in Flutter gradient subclasses that sample once, then delegate rendering to native Flutter shaders. |
| `test/` | Mathematical, API-contract, renderer-model, and approximation regression tests. |
| `example/lib/main.dart` | Interactive Playground and Accuracy Lab. |
| `example/lib/comparison_page.dart` | Fixed teaching catalog that compares curves, spaces, geometry, stops, and density. |
| `example/lib/edge_fade_page.dart` | `ShaderMask` alpha-mask recipe and its live controls. |
| `example/lib/benchmark/` | Profile-mode construction and frame benchmark workload. |
| `example/integration_test/` | Device benchmark orchestration. |
| `tool/generate_readme_images.dart` | Regenerates the README figures in `doc/images/`. |
| `doc/images/` | Generated README figures. Edit the generator, never the PNGs. |
| `docs/benchmarks/` | Recorded methodology, results, and interpretation limits. |

## End-to-end data flow

A caller creates an easing gradient from compact source colors:

```text
source colors + optional positions
              |
              v
easeColorStops
  resolve positions
  choose curve per transition
  sample progress values
  mix colors in selected color space
  add transparent endpoint guards
  deduplicate shared boundaries
              |
              v
immutable generated colors + stops
              |
              v
Flutter LinearGradient / RadialGradient / SweepGradient
              |
              v
native createShader implementation
```

The easing curve and color-space conversions run during construction, not inside the shader. The shader receives ordinary Flutter colors and stop positions.

## Sampling model

For each positive-width transition from source color `i` to `i + 1`:

1. Resolve the transition curve from `transitionCurves[i]`, falling back to the global curve.
2. Divide progress into `samplesPerTransition + 1` equal intervals.
3. Evaluate the curve at both endpoints and every interior position.
4. Interpolate the endpoint colors by the eased value in the selected color space.
5. Place each generated color at the original, uneased geometric progress position.

The renderer linearly interpolates between these generated points. More interior points improve the piecewise-linear approximation but increase construction work, output-list memory, and native shader stop count.

### Boundary deduplication

Adjacent source transitions both evaluate their shared endpoint. `emit` removes a new entry only when both its position and color exactly repeat the previous entry. This keeps normal shared boundaries compact while preserving hard edges, where the position is repeated with a different color.

### Coincident source stops

Two source stops at the same position describe a hard edge. The sampler emits both endpoint colors at that position and skips smooth sampling for the zero-width interval.

### Transparent endpoint guards

Flutter's native shader interpolates supplied stops in straight RGBA, then premultiplies the fragment. A fully transparent color can contain hidden RGB that would otherwise leak into the final interval.

Before an exact transparent endpoint, the sampler adds another zero-alpha stop carrying the visible limiting RGB of the neighboring sample. Both stops occupy the endpoint position, so the caller's exact source color remains inspectable while the limiting stop protects the visible interval.

This guard can increase output count by one per transparent transition boundary.

## Color interpolation

All colors enter and leave the interpolation engine as sRGB. Display P3 and other wide-gamut inputs are converted first, which can discard colors outside sRGB.

### Rectangular spaces

The rectangular spaces are sRGB, linear RGB, and OKLab. Their three components are multiplied by alpha, interpolated, then divided by interpolated alpha. A near-zero-alpha guard avoids unstable division.

### Polar spaces

OKLCH and HSL have an angular hue component. Their non-hue components are alpha-weighted, while hue follows the shorter angular path. An achromatic endpoint borrows the other endpoint's hue because its own hue is powerless.

A fully transparent chromatic endpoint can still influence hue in a polar space. Alpha premultiplication does not erase the separate angular path.

### Gamut policy

After conversion back to sRGB, alpha and every channel are independently clipped to `[0, 1]`. This is fast and deterministic, but it is not perceptual gamut mapping. Clipping can change chroma or hue and can flatten overshooting curves near gamut boundaries.

## StepsCurve

`StepsCurve` is both a normal Flutter `Curve` and a signal to the sampler to emit exact hard bands. The sampler does not approximate it with dense smooth stops.

Each band is represented by the same color at its start and end. At a jump coordinate, the previous band's ending color and the next band's starting color share one position. Native backends can choose one side at that single coordinate, but no visible ramp exists between the bands.

`Curve.transform` must map exact progress 0 and 1 to themselves. Gradient sampling uses `stepValue` directly where CSS step endpoint behavior differs from that Flutter contract.

## Gradient subclasses

Each public gradient class has a non-const factory and a private const generative constructor:

1. The factory calls `easeColorStops`.
2. It defensively copies compact source configuration.
3. The private constructor passes generated lists to the Flutter superclass.

Inherited `colors` and `stops` are shader-ready dense lists. `sourceColors` and `sourceStops` preserve compact caller input.

Value equality includes source configuration and geometry, not only rendered dense lists. Two configurations that paint the same flat color can still compare unequal if their public easing settings differ.

Flutter's inherited `scale`, `withOpacity`, `fromColor`, and interpolation methods return base gradient classes. The generated stops, and therefore the appearance, remain. Package-specific source metadata and runtime type do not.

## Example application

### Compare gallery

`comparison_page.dart` is a fixed teaching curriculum. Stable section and case IDs feed widget-test keys. Preview modes are diagnostic fixtures:

- scrim: makes an overlay seam visible;
- swatch: compares color paths and pacing;
- transparency: checkerboard reveals hidden RGB;
- bands: shallow strip exposes hard stops;
- geometry: extra area reveals radial and sweep shape.

The custom 700-pixel breakpoint is based on room for two legible preview cards, not a device category.

### Edge fade

`edge_fade_page.dart` demonstrates the gradient as an alpha mask rather than as paint. `EdgeFade` builds the mask in `build` and passes `createShader` to `ShaderMask`, because `ShaderMask` requests a shader on every paint and constructing the gradient inside the callback would resample the curve on every frame of a scroll.

The preview keeps a real scrollable inside the mask so content is seen dissolving as it passes under the edge. The extent is clamped to a half so the two fades cannot cross and ask for descending stops.

### Playground

Playground applies one set of interpolation controls to linear, radial, and sweep geometry. It is intended to show API consistency rather than benchmark performance.

### Accuracy Lab

Accuracy Lab compares three outputs that must share endpoints, curve, color space, and sample count:

1. production generated-stop native gradient;
2. direct CPU curve and color evaluation per layout column;
3. amplified absolute premultiplied-channel difference.

The CPU strip is exact only at displayed column resolution. The difference strip is not a perceptual color-distance metric.

## Performance benchmark

The benchmark compares three variants per geometry:

- compact native gradient with source colors;
- dense native gradient with precomputed generated lists;
- easing wrapper constructed from source colors.

Dense native versus easing isolates wrapper overhead. Compact native versus easing shows the practical cost of carrying additional native stops.

One cached gradient object creates shaders for 64 animated tile rectangles every frame. The benchmark does not reconstruct 64 gradients every frame.

See `docs/benchmarks/gradient-performance.md` for the runnable command, JSON schema, recorded results, and limitations.

## README figures

`doc/images/` is generated output. `tool/generate_readme_images.dart` paints each figure straight onto a recorded canvas using the same public gradient objects a caller would build, so a figure cannot drift away from what the package actually renders.

Most figures contain no text, and their labels live in the README tables around them. The edge-fade comparison deliberately uses readable paragraphs and text list tiles because fading letterforms demonstrates that recipe better than abstract bars. `flutter_test` normally substitutes the Ahem test font, so the generator loads the tracked Roboto Regular from `tool/fonts/` before painting those figures. Its provenance and Apache 2.0 license are stored beside the font. The generator and font are repository-only inputs excluded from the pub archive; their generated figures remain published. Regenerate and optimize with:

```sh
flutter test tool/generate_readme_images.dart
python3 tool/optimize_readme_images.py
```

The optimizer first runs OxiPNG at maximum lossless compression with safe metadata stripping and no interlacing. It keeps the dithered hero scrims as PNG because they compress better there, and converts every other figure to exact lossless WebP. Before replacing a source PNG, it compares dimensions and decoded RGBA hashes. The optimized hybrid is smaller than either all-PNG or all-WebP output.

## Testing responsibilities

- `color_space_test.dart`: conversion reference values, round trips, hue path, and alpha behavior.
- `eased_color_stops_test.dart`: endpoint identity, counts, normalization, deduplication, hard edges, transparent guards, and preconditions.
- `steps_curve_test.dart`: every step position and duplicated hard-stop output.
- `easing_gradient_test.dart`: Flutter subtype behavior, geometry forwarding, equality, inherited operations, shader creation, and widget rendering.
- `approximation_accuracy_test.dart`: continuous CPU reference versus generated-stop renderer model.
- `example/test/widget_test.dart`: navigation, lazy catalog coverage, narrow/wide layout behavior, and edge-fade mask construction.

## Change checklist

When changing sampling or color math:

1. Update dartdoc and this guide if an invariant changes.
2. Add or update a focused mathematical regression test.
3. Re-run the approximation suite across every color space.
4. Verify transparent endpoints still have limiting-color guards.
5. Generate API docs and resolve every warning.
6. Run package and example analysis/tests.
7. Regenerate the README figures, because they are rendered from the real sampler.
8. Re-run profile benchmarks if generated stop count or painting behavior changes.

Commands:

```sh
flutter analyze
flutter test
flutter test tool/generate_readme_images.dart
python3 tool/optimize_readme_images.py
dart doc

cd example
flutter analyze
flutter test
```
