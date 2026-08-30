# Gradient Performance Benchmark

## Result summary

On a physical iPhone running iOS 26.6.1 at 120 Hz, all tested linear, radial, and sweep variants sustained **119.99 FPS with zero build-or-raster budget exceedances** while continuously repainting **64 gradient tiles per frame**. This jank metric does not classify late frame intervals or total-span overruns independently.

The easing wrappers and stop-matched dense native controls produced very similar raster times in this run. Their median p90 raster difference was 12 μs for linear, -79 μs for radial, and 16 μs for sweep. These are small observed differences relative to the 8,333 μs frame budget and are consistent with the package architecture: easing is precomputed, while painting uses Flutter's native gradient shader. Three fixed-order repetitions are not enough to classify the deltas statistically as measurement noise.

A compact native gradient with only three source colors rasterized faster than the dense versions, as expected. The eased gradients carry roughly 35 generated stops for this three-color case.

## Environment

- Build mode: Flutter profile
- Platform: physical iPhone, wireless deployment
- OS: iOS 26.6.1 (23G83)
- Flutter: 3.47.1 stable
- Framework revision: 6655482ec0
- Engine revision: 5d53178869
- Display: 390 × 844 logical pixels, 3× device pixel ratio
- Refresh rate: 120 Hz
- Refresh budget: 8,333 μs
- Workload: 64 continuously repainted gradient tiles
- Warmup: 2 seconds plus a 2-second timing-batch drain
- Measurement: 5 seconds per repetition
- Repetitions: 3 per scenario

## Frame results

Values are medians across the three repetitions. Raster and build values are p90 unless marked p99.

| Geometry | Variant | FPS | Frame interval p90 | Build p90 | Raster p90 | Raster p99 | Jank |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Linear | Native compact | 119.99 | 8.391 ms | 0.678 ms | 0.638 ms | 0.724 ms | 0% |
| Linear | Native dense | 119.99 | 8.377 ms | 0.819 ms | 0.802 ms | 0.972 ms | 0% |
| Linear | Easing wrapper | 119.99 | 8.385 ms | 0.839 ms | 0.814 ms | 1.023 ms | 0% |
| Radial | Native compact | 119.99 | 8.384 ms | 0.637 ms | 0.617 ms | 0.677 ms | 0% |
| Radial | Native dense | 119.99 | 8.379 ms | 0.814 ms | 1.012 ms | 1.647 ms | 0% |
| Radial | Easing wrapper | 119.99 | 8.381 ms | 0.802 ms | 0.933 ms | 1.684 ms | 0% |
| Sweep | Native compact | 119.99 | 8.393 ms | 0.660 ms | 0.620 ms | 0.679 ms | 0% |
| Sweep | Native dense | 119.99 | 8.381 ms | 0.836 ms | 0.854 ms | 1.565 ms | 0% |
| Sweep | Easing wrapper | 119.99 | 8.377 ms | 0.815 ms | 0.870 ms | 1.580 ms | 0% |

### Raster comparison

| Geometry | Easing vs compact native | Easing vs dense native | Dense-control delta |
| --- | ---: | ---: | ---: |
| Linear | 1.276× p90 raster | 1.015× | +0.012 ms |
| Radial | 1.512× p90 raster | 0.922× | -0.079 ms |
| Sweep | 1.403× p90 raster | 1.019× | +0.016 ms |

The compact comparison answers the practical question: more color stops cost some GPU work. The dense comparison isolates the package wrapper from that stop-count cost. Dense native and easing are the same shader workload, and their observed difference is negligible.

Even the worst p99 measurement, 1.684 ms for eased radial, uses only about 20% of the 8.333 ms 120 Hz budget under the 64-tile stress workload.

## Construction results

Construction values are microseconds per operation, measured in warmed batches of 250 operations across 30 batches. Each timed operation constructs a gradient and reads its `hashCode` into a black-hole accumulator. The numbers therefore represent constructor-plus-hash throughput, not pure allocation latency; comparisons are meaningful within the same geometry and process.

| Geometry | Native compact median | Native dense median | Easing median | Easing / compact | Easing / dense |
| --- | ---: | ---: | ---: | ---: | ---: |
| Linear | 1.148 μs | 3.628 μs | 11.952 μs | 10.4× | 3.3× |
| Radial | 0.152 μs | 1.300 μs | 11.836 μs | 77.9× | 9.1× |
| Sweep | 0.164 μs | 1.292 μs | 11.880 μs | 72.4× | 9.2× |

The relative ratios look large because native constructors are extremely cheap. In absolute terms, the full default easing construction is approximately **12 μs**, or about **0.14% of one 120 Hz frame budget**. Static gradients should still be cached or hoisted when convenient, especially when many are created in every build.

## Reproducing the benchmark

Prerequisites:

- Flutter 3.47.1 or a compatible SDK
- a physical Flutter-supported device
- valid platform signing and deployment setup
- device power, orientation, refresh-rate, and thermal conditions kept as stable as possible

Run from the example directory in profile mode:

```sh
cd example
flutter drive --profile \
  -d <physical-device-id> \
  --target integration_test/gradient_performance_test.dart \
  --driver test_driver/performance_driver.dart
```

The test rejects debug and release execution because this harness uses profile-mode VM reporting and the recorded results are profile measurements. It writes a local, gitignored artifact to `example/build/performance/gradient_benchmark.json`. Copy that file before cleaning `build/` if the raw run must be retained.

## Methodology

Each geometry has three controls:

1. **Native compact**: Flutter's normal gradient with three source colors.
2. **Native dense**: Flutter's normal gradient given the exact generated colors and stops from `easeColorStops`.
3. **Easing wrapper**: `EasingLinearGradient`, `EasingRadialGradient`, or `EasingSweepGradient` from the same source colors.

One `Gradient` object is cached per scenario. A `CustomPainter` repaints 64 tiles every frame, creates 64 native shaders from that cached gradient using changing rectangles, and draws 64 rectangles. The changing bounds force shader creation and raster work rather than testing only compositor reuse. The gradient objects themselves are not regenerated every frame.

FPS comes from first-to-last engine vsync timestamps, not test wall-clock duration. The reported jank count uses the real 120 Hz display budget and counts a timing when either build or raster exceeds 8,333 μs. It does not independently count long vsync intervals or `totalSpan` overruns, so interpret it as a phase-budget diagnostic rather than a complete presentation-jank metric.

`FrameTiming` arrives asynchronously in batches. The collector remains attached for 500 ms after animation stops so it does not lose the last measured batch. That flush can include a small number of post-animation frames. FPS remains cadence-based because it uses engine vsync timestamps; `elapsed_us` in the JSON is the requested animation interval and should not be combined with `frame_count` to recompute FPS.

### JSON schema

The generated JSON has four top-level keys:

- `schema_version`: currently `1`.
- `environment`: profile mode, platform and OS string, display dimensions, pixel ratio, refresh rate, workload size, warmup, measurement duration, and repetitions.
- `construction`: keys use `geometry/variant` with snake-case variants such as `linear/native_compact`; each value contains raw sorted microseconds-per-operation batches and summary statistics.
- `frames`: keys use `geometry/variant` with Dart enum names such as `linear/nativeCompact`; each value is an array of repetition objects. Durations and intervals are microseconds. Every repetition contains raw sorted build, raster, total-span, and frame-interval arrays plus summary statistics, cadence FPS, and phase-budget jank counts.

Raw machine-readable samples are generated locally at:

`example/build/performance/gradient_benchmark.json`

This path is ignored by version control. The checked-in report records the summarized run, not its generated raw artifact.

The benchmark harness lives in:

- `example/lib/benchmark/gradient_benchmark.dart`
- `example/integration_test/gradient_performance_test.dart`
- `example/test_driver/performance_driver.dart`

## Caveats

- This is one physical iPhone, one Flutter/engine revision, and one renderer configuration. The exact iPhone model and renderer backend were not recorded, so the run cannot classify model-specific GPU performance.
- Xcode/host versions, Low Power Mode, battery state, and device orientation were not captured in the JSON.
- Wireless deployment can slow installation but does not participate in collected on-device frame timings.
- Thermal state was not independently recorded.
- Scenarios ran in a fixed order, so temperature, frequency scaling, cache state, and temporal drift can correlate with geometry or variant.
- Three repetitions provide a useful local comparison but no confidence interval or cross-device guarantee. Table values are medians of per-repetition percentiles, not percentiles pooled across all frames.
- Web, Android, macOS, lower-end devices, different stop counts, and different color spaces are separate benchmark populations.
- The stress workload paints 64 tiles and creates 64 shaders each frame from one cached gradient object. It does not rebuild 64 easing gradients each frame.
