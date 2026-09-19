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
| `example/lib/main.dart` | Root app: theme controller, destination state, and shell. |
| `example/lib/home_page.dart` | Landing page: hero, one comparison, feature blocks, closing call to action. |
| `example/lib/docs_page.dart`, `example/lib/src/docs/` | Documentation page, section metadata, and prose components. |
| `example/lib/src/theme/` | Design tokens, the Material theme built from them, and the light/dark controller. |
| `example/lib/src/widgets/` | Site chrome: nav shell, content container and sections, footer, and the themed control set. |
| `example/lib/examples_page.dart` | Recreated website gradients, palette boards, and the pluto collection. |
| `example/lib/playground_page.dart` | Interactive geometry, curve, color-space, and density matrix. |
| `example/lib/accuracy_lab_page.dart` | Physical-column CPU models and sampling comparisons. |
| `example/lib/alpha_fade.dart`, `example/shaders/alpha_fade.frag` | Example-only analytic alpha mask and stationary alpha-noise experiment. |
| `example/lib/src/widgets/iphone_frame.dart` | iPhone 17 Pro body from `device_preview` presets, scaled around a widget subtree. |
| `example/lib/comparison_page.dart` | Fixed teaching catalog that compares curves, spaces, geometry, stops, and density. |
| `example/lib/edge_fade_page.dart` | `ShaderMask` alpha-mask recipe and its live controls. |
| `example/lib/benchmark/` | Profile-mode construction and frame benchmark workload. |
| `example/integration_test/` | Device benchmark orchestration. |
| `tool/generate_readme_images.dart` | Regenerates the README figures in `doc/images/`. |
| `doc/images/` | Generated README figures. Edit the generator, never the PNGs. |
| `doc/benchmarks/` | Recorded methodology, results, and interpretation limits. |

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

The default output remains sRGB. The optional `outputColorSpace` selects Display P3 or extended-sRGB output independently of `EasingColorSpace`. Opt-in non-HSL interpolation uses extended-sRGB working coordinates, retaining out-of-sRGB values through color conversion. HSL explicitly retains bounded sRGB working coordinates. Correct primaries conversion is required before tagging output; tags alone do not convert colors.

### Rectangular spaces

The rectangular spaces are sRGB, linear RGB, and OKLab. Their three components are multiplied by alpha, interpolated, then divided by interpolated alpha. A near-zero-alpha guard avoids unstable division.

### Polar spaces

OKLCH and HSL have an angular hue component. Their non-hue components are alpha-weighted, while hue follows the shorter angular path. An achromatic endpoint borrows the other endpoint's hue because its own hue is powerless.

A fully transparent chromatic endpoint can still influence hue in a polar space. Alpha premultiplication does not erase the separate angular path.

### Gamut policy

Alpha is clipped to `[0, 1]`. Bounded sRGB and P3 outputs clip RGB only after conversion into their output primaries; extended-sRGB output retains negative and greater-than-one RGB. Bounded clipping is not perceptual gamut mapping. Renderer adapters, surfaces, and displays can still discard precision or gamut. In the inspected Flutter 3.47.4 SDK, native Skia and web gradient adapters pack stops into 8-bit ARGB; native Float32 input alone does not establish end-to-end precision.

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

Flutter's inherited `scale`, `withOpacity`, `fromColor`, and interpolation methods return base gradient classes. The generated stops, and therefore the appearance, remain. Package-specific source metadata and runtime type do not. Extended-sRGB output is an exception to unrestricted inherited-operation compatibility: Flutter 3.47.4 `Color.lerp` asserts on these colors. Rebuild from source configuration instead of relying on inherited scale/lerp for extended output.

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

`edge_fade_page.dart` demonstrates the gradient as an alpha mask rather than as paint. Its two content examples, a compact list and a paragraph reader, render inside the iPhone 17 Pro preset frame. `device_preview` 3 paints its device body outside the render object's own bounds and expects that object to be exactly the simulated screen, so `IPhone17ProFrame` reserves the full body rectangle, scales it, and offsets the screen back to the frame origin. `EdgeFade` builds the mask in `build` and passes `createShader` to `ShaderMask`, because `ShaderMask` requests a shader on every paint and constructing the gradient inside the callback would resample the curve on every frame of a scroll.

The preview keeps a real scrollable inside the mask so content is seen dissolving as it passes under the edge. The extent is clamped to a half so the two fades cannot cross and ask for descending stops.

### Site template

The example is presented as a website, not a phone app. `src/theme/tokens.dart` holds an `AppColors` theme extension plus radius, layout, and font constants; `src/theme/app_theme.dart` turns those into a `ThemeData` that also flattens Material's stock slider, switch, dropdown, and segmented-button styling. `src/widgets/app_shell.dart` owns the sticky nav, the destination enum, the compact menu sheet, and the footer. `src/widgets/section.dart` provides the centered content column and heading scale, and `src/widgets/controls.dart` the labelled control set and the preview-beside-controls layout.

Destination links carry stable `nav-<slug>` keys because several destinations share a name with the heading on the page they open. The nav collapses into a menu below `AppLayout.compactBreakpoint`, which is independent of the comparison catalog's own 700-pixel card breakpoint.

### Examples

`examples_page.dart` recreates gradients from reference screenshots and mirrors the full pluto background collection. It is a wide visual surface: a change in sampling or color math shows up across roughly 200 fades at once.

### Playground

Playground applies one set of interpolation controls to linear, radial, and sweep geometry. It is intended to show API consistency rather than benchmark performance.

### Accuracy Lab

Accuracy Lab compares production uniform, dense uniform, and experimental placement through native shaders. Separate CPU reference and residual strips sample physical-column centers using nonoverlapping, non-antialiased rectangles. Reference colors are composited onto an explicit opaque background before painting.

The model metric includes alpha and source-over RGB differences on black/white backgrounds. The preview residual uses the selected background. Neither reads the framebuffer, and both reference and sampled colors share `mixColors`. They cannot validate color math independently or establish freedom from display banding. The reference is still subject to backend color encoding.

`benchmark/sampling.dart` keeps bounded Bézier-parameter and adaptive sampling example-local. Cubic placement evaluates Flutter's actual curve at nonuniform x positions; adaptive placement probes multiple positions and has a fixed stop budget, not a universal error guarantee. Steps remain on the exact production band path.

The Edge fade shader experiment targets alpha, because `BlendMode.dstIn` ignores RGB. It compares identical analytic one-layer masks with zero noise versus adjustable stationary alpha noise. This is not the same composition workload as the original two-native-mask recipe. Endpoints are pinned and noise is clamped; visual quality and any bias near endpoints still require on-display checking.

## Performance benchmark

The benchmark compares three variants per geometry:

- compact native gradient with source colors;
- dense native gradient with precomputed generated lists;
- easing wrapper constructed from source colors.

Dense native versus easing isolates wrapper overhead. Compact native versus easing shows the practical cost of carrying additional native stops.

One cached gradient object creates shaders for 64 animated tile rectangles every frame. The benchmark does not reconstruct 64 gradients every frame.

See `doc/benchmarks/gradient-performance.md` for the runnable command, JSON schema, recorded results, and limitations.

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
