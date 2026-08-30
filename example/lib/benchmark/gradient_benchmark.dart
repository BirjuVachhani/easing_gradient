import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FramePhase;

import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Shared source palette for every control and easing scenario.
///
/// Three colors create two transitions and exercise the package's transparent
/// endpoint guard. The stop-matched native control below receives exactly the
/// dense lists generated from this same palette.
const _sourceColors = <Color>[
  Color(0xFF4F46E5),
  Color(0xFFEC4899),
  Color(0x00F59E0B),
];

/// Gradient geometry under benchmark.
enum BenchmarkGeometry { linear, radial, sweep }

/// Controls used to separate stop-count cost from package-wrapper cost.
///
/// [nativeCompact] is normal Flutter usage with three source colors.
/// [nativeDense] is a Flutter gradient with the exact colors and stops produced
/// by [easeColorStops]. [easing] constructs the package wrapper from the compact
/// colors. Dense native versus easing isolates per-frame wrapper overhead.
enum BenchmarkVariant { nativeCompact, nativeDense, easing }

extension on BenchmarkGeometry {
  String get label => name;
}

extension on BenchmarkVariant {
  String get label => switch (this) {
    BenchmarkVariant.nativeCompact => 'native_compact',
    BenchmarkVariant.nativeDense => 'native_dense',
    BenchmarkVariant.easing => 'easing',
  };
}

final EasedColorStops _denseStops = easeColorStops(
  colors: _sourceColors,
  curve: Curves.easeInOut,
  colorSpace: EasingColorSpace.oklab,
);

/// Constructs one benchmark gradient with geometry held constant across controls.
///
/// Dense stops are precomputed outside this function. Constructor timings for
/// [BenchmarkVariant.nativeDense] therefore measure only native object creation,
/// while [BenchmarkVariant.easing] includes stop generation and color conversion.
Gradient createBenchmarkGradient(
  BenchmarkGeometry geometry,
  BenchmarkVariant variant,
) {
  final colors = variant == BenchmarkVariant.nativeCompact
      ? _sourceColors
      : _denseStops.colors;
  final stops = variant == BenchmarkVariant.nativeCompact
      ? null
      : _denseStops.stops;

  return switch ((geometry, variant)) {
    (BenchmarkGeometry.linear, BenchmarkVariant.easing) => EasingLinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _sourceColors,
    ),
    (BenchmarkGeometry.linear, _) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: stops,
    ),
    (BenchmarkGeometry.radial, BenchmarkVariant.easing) => EasingRadialGradient(
      center: const Alignment(-0.25, -0.3),
      radius: 0.85,
      colors: _sourceColors,
    ),
    (BenchmarkGeometry.radial, _) => RadialGradient(
      center: const Alignment(-0.25, -0.3),
      radius: 0.85,
      colors: colors,
      stops: stops,
    ),
    (BenchmarkGeometry.sweep, BenchmarkVariant.easing) => EasingSweepGradient(
      center: const Alignment(0.1, -0.1),
      startAngle: math.pi / 8,
      endAngle: math.pi * 15 / 8,
      colors: _sourceColors,
    ),
    (BenchmarkGeometry.sweep, _) => SweepGradient(
      center: const Alignment(0.1, -0.1),
      startAngle: math.pi / 8,
      endAngle: math.pi * 15 / 8,
      colors: colors,
      stops: stops,
    ),
  };
}

/// Runs warmed, batched constructor benchmarks inside the Flutter engine.
///
/// Each sample times [iterationsPerBatch] constructor calls and divides the
/// elapsed microseconds by that count, reducing per-Stopwatch overhead. The
/// timed operation also reads each object's [Object.hashCode] into a black-hole
/// accumulator so profile-mode optimization cannot discard it. Consequently,
/// results are constructor-plus-hash throughput, not pure allocation latency.
/// Run comparisons within the same geometry and device process.
Map<String, Object?> runConstructionBenchmarks({
  int batches = 30,
  int iterationsPerBatch = 250,
}) {
  final results = <String, Object?>{};
  var blackHole = 0;

  for (final geometry in BenchmarkGeometry.values) {
    for (final variant in BenchmarkVariant.values) {
      for (var i = 0; i < 100; i++) {
        blackHole ^= createBenchmarkGradient(geometry, variant).hashCode;
      }

      final samples = <double>[];
      for (var batch = 0; batch < batches; batch++) {
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterationsPerBatch; i++) {
          blackHole ^= createBenchmarkGradient(geometry, variant).hashCode;
        }
        stopwatch.stop();
        samples.add(stopwatch.elapsedMicroseconds / iterationsPerBatch);
      }
      samples.sort();
      results['${geometry.label}/${variant.label}'] = {
        'iterations_per_batch': iterationsPerBatch,
        'batches': batches,
        'samples_us_per_op': samples,
        'median_us_per_op': percentile(samples, 0.5),
        'p90_us_per_op': percentile(samples, 0.9),
        'p99_us_per_op': percentile(samples, 0.99),
        'mean_us_per_op': samples.reduce((a, b) => a + b) / samples.length,
        'min_us_per_op': samples.first,
        'max_us_per_op': samples.last,
      };
    }
  }

  // Keeps every constructed object observable to the optimizer.
  results['black_hole'] = blackHole;
  return results;
}

/// Returns the nearest-rank-like sample at [fraction] from an ascending list.
///
/// Callers must sort [sorted] and supply a fraction in `[0, 1]`. Clamping is a
/// release-mode guard, not a supported way to request an out-of-range percentile.
double percentile(List<double> sorted, double fraction) {
  assert(
    sorted.isNotEmpty,
    'A percentile needs at least one observation to summarize.',
  );
  assert(
    fraction >= 0 && fraction <= 1,
    'A percentile fraction must identify a position between 0 and 1.',
  );
  assert(
    _isNonDecreasing(sorted),
    'Percentile input must be sorted in ascending order before summarization.',
  );
  final index = ((sorted.length - 1) * fraction).round();
  return sorted[index.clamp(0, sorted.length - 1)];
}

bool _isNonDecreasing(List<double> values) {
  for (var index = 1; index < values.length; index++) {
    if (values[index] < values[index - 1]) return false;
  }
  return true;
}

/// An isolated, continuously repainted gradient workload.
class GradientBenchmarkApp extends StatefulWidget {
  const GradientBenchmarkApp({super.key});

  @override
  State<GradientBenchmarkApp> createState() => GradientBenchmarkAppState();
}

class GradientBenchmarkAppState extends State<GradientBenchmarkApp>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  BenchmarkGeometry geometry = BenchmarkGeometry.linear;
  BenchmarkVariant variant = BenchmarkVariant.nativeCompact;
  int tileCount = 64;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> configure(
    BenchmarkGeometry nextGeometry,
    BenchmarkVariant nextVariant,
  ) async {
    controller.stop();
    setState(() {
      geometry = nextGeometry;
      variant = nextVariant;
    });
    await SchedulerBinding.instance.endOfFrame;
  }

  void start() => controller.repeat();
  void stop() => controller.stop();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = createBenchmarkGradient(geometry, variant);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('gradient-benchmark-surface'),
            painter: _GradientBenchmarkPainter(
              gradient: gradient,
              animation: controller,
              tileCount: tileCount,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _GradientBenchmarkPainter extends CustomPainter {
  _GradientBenchmarkPainter({
    required this.gradient,
    required this.animation,
    required this.tileCount,
  }) : super(repaint: animation);

  final Gradient gradient;
  final Animation<double> animation;
  final int tileCount;

  @override
  void paint(Canvas canvas, Size size) {
    final columns = math.sqrt(tileCount).ceil();
    final rows = (tileCount / columns).ceil();
    final tileWidth = size.width / columns;
    final tileHeight = size.height / rows;
    final phase = animation.value * math.pi * 2;

    for (var index = 0; index < tileCount; index++) {
      final column = index % columns;
      final row = index ~/ columns;
      final inset = 1 + (math.sin(phase + index * 0.37) + 1) * 1.5;
      final rect = Rect.fromLTWH(
        column * tileWidth + inset,
        row * tileHeight + inset,
        tileWidth - inset * 2,
        tileHeight - inset * 2,
      );
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientBenchmarkPainter oldDelegate) =>
      oldDelegate.gradient != gradient ||
      oldDelegate.tileCount != tileCount ||
      oldDelegate.animation != animation;
}

/// Collects engine [FrameTiming] batches and produces refresh-aware statistics.
///
/// Flutter delivers timings asynchronously in batches. [stopAndFlush] keeps the
/// callback attached for 500 ms after animation stops so the final measured
/// batch is not lost. That flush window can also contribute a small number of
/// post-animation frames. Duration percentiles and engine-vsync cadence remain
/// valid; [elapsed_us] records only the requested animation interval and should
/// not be used to recompute FPS from [frame_count]. [summarize] instead derives
/// FPS from first-to-last engine vsync timestamps.
///
/// `janky_frame_count` is a phase-budget diagnostic: it counts a timing when
/// either build or raster duration exceeds one detected refresh interval. It is
/// not a complete late-presentation count because it does not classify long
/// frame intervals or [FrameTiming.totalSpan] independently.
class FrameTimingCollector {
  final timings = <FrameTiming>[];
  void _callback(List<FrameTiming> batch) => timings.addAll(batch);

  void start() {
    timings.clear();
    SchedulerBinding.instance.addTimingsCallback(_callback);
  }

  Future<void> stopAndFlush() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    SchedulerBinding.instance.removeTimingsCallback(_callback);
  }

  /// Summarizes one repetition.
  ///
  /// Raw arrays are sorted for percentile reproducibility. All durations and
  /// intervals in the JSON are microseconds; `effective_fps` is calculated from
  /// engine vsync timestamps rather than the test-pump stopwatch.
  Map<String, Object?> summarize({
    required Duration elapsed,
    required double refreshRate,
  }) {
    final build =
        timings
            .map((timing) => timing.buildDuration.inMicroseconds.toDouble())
            .toList()
          ..sort();
    final raster =
        timings
            .map((timing) => timing.rasterDuration.inMicroseconds.toDouble())
            .toList()
          ..sort();
    final total =
        timings
            .map((timing) => timing.totalSpan.inMicroseconds.toDouble())
            .toList()
          ..sort();
    final budget = Duration.microsecondsPerSecond / refreshRate;
    final vsyncStarts = timings
        .map(
          (timing) =>
              timing.timestampInMicroseconds(FramePhase.vsyncStart).toDouble(),
        )
        .toList();
    final frameIntervals = <double>[
      for (var i = 1; i < vsyncStarts.length; i++)
        vsyncStarts[i] - vsyncStarts[i - 1],
    ]..sort();
    final observedSpan = vsyncStarts.length < 2
        ? 0.0
        : vsyncStarts.last - vsyncStarts.first + budget;
    final uniqueJank = timings
        .where(
          (timing) =>
              timing.buildDuration.inMicroseconds > budget ||
              timing.rasterDuration.inMicroseconds > budget,
        )
        .length;

    Map<String, Object?> stats(List<double> values) => values.isEmpty
        ? const {'count': 0}
        : {
            'count': values.length,
            'mean_us': values.reduce((a, b) => a + b) / values.length,
            'p50_us': percentile(values, 0.5),
            'p90_us': percentile(values, 0.9),
            'p99_us': percentile(values, 0.99),
            'worst_us': values.last,
          };

    return {
      'elapsed_us': elapsed.inMicroseconds,
      'refresh_rate_hz': refreshRate,
      'refresh_budget_us': budget,
      'frame_count': timings.length,
      'effective_fps': observedSpan == 0
          ? 0
          : timings.length * Duration.microsecondsPerSecond / observedSpan,
      'frame_intervals': stats(frameIntervals),
      'raw_frame_intervals_us': frameIntervals,
      'janky_frame_count': uniqueJank,
      'janky_frame_percent': timings.isEmpty
          ? 0
          : uniqueJank * 100 / timings.length,
      'build': stats(build),
      'raster': stats(raster),
      'total_span': stats(total),
      'raw_build_us': build,
      'raw_raster_us': raster,
      'raw_total_span_us': total,
    };
  }
}
