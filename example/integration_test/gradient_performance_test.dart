import 'dart:io';

import 'package:easing_gradient_example/benchmark/gradient_benchmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Profile-mode device benchmark for construction and sustained painting.
///
/// Run from `example/` with:
///
/// ```sh
/// flutter drive --profile \
///   -d <physical-device-id> \
///   --target integration_test/gradient_performance_test.dart \
///   --driver test_driver/performance_driver.dart
/// ```
///
/// The fixed scenario order makes runs easy to compare but does not eliminate
/// thermal drift or cache-order effects. The report treats three repetitions as
/// a local comparison, not a confidence interval or cross-device guarantee.
void main() {
  const isProfile = bool.fromEnvironment('dart.vm.profile');
  if (!isProfile) {
    throw StateError(
      'Gradient performance results are valid only in profile mode. Run with '
      'flutter drive --profile.',
    );
  }
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('gradient construction and frame performance', (tester) async {
    final key = GlobalKey<GradientBenchmarkAppState>();
    await tester.pumpWidget(GradientBenchmarkApp(key: key));
    await tester.pumpAndSettle();

    final view = tester.view;
    final refreshRate = view.display.refreshRate;
    final frameResults = <String, Object?>{};
    const warmup = Duration(seconds: 2);
    const measurement = Duration(seconds: 5);
    const repetitions = 3;

    for (final geometry in BenchmarkGeometry.values) {
      for (final variant in BenchmarkVariant.values) {
        final repetitionsData = <Map<String, Object?>>[];
        for (var repetition = 0; repetition < repetitions; repetition++) {
          await key.currentState!.configure(geometry, variant);
          key.currentState!.start();
          await tester.pump(warmup);
          key.currentState!.stop();
          // FrameTiming arrives in delayed batches. Leave the callback detached
          // while the warmup tail drains so those frames cannot inflate FPS.
          await tester.pump(const Duration(seconds: 2));

          final collector = FrameTimingCollector()..start();
          key.currentState!.start();
          final stopwatch = Stopwatch()..start();
          await tester.pump(measurement);
          key.currentState!.stop();
          stopwatch.stop();
          await collector.stopAndFlush();

          repetitionsData.add(
            collector.summarize(
              elapsed: stopwatch.elapsed,
              refreshRate: refreshRate,
            ),
          );
        }
        frameResults['${geometry.name}/${variant.name}'] = repetitionsData;
      }
    }

    binding.reportData = {
      'schema_version': 1,
      'environment': {
        'flutter_mode': 'profile',
        'platform': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'refresh_rate_hz': refreshRate,
        'logical_width': view.physicalSize.width / view.devicePixelRatio,
        'logical_height': view.physicalSize.height / view.devicePixelRatio,
        'device_pixel_ratio': view.devicePixelRatio,
        'tile_count': key.currentState!.tileCount,
        'warmup_seconds': warmup.inMilliseconds / 1000,
        'measurement_seconds': measurement.inMilliseconds / 1000,
        'repetitions': repetitions,
      },
      'construction': runConstructionBenchmarks(),
      'frames': frameResults,
    };
  }, timeout: const Timeout(Duration(minutes: 8)));
}
