import 'dart:convert';
import 'dart:io';

import 'package:easing_gradient/easing_gradient.dart';
import 'package:easing_gradient_example/benchmark/sampling.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

// Run from example with:
// flutter test --dart-define=SAMPLING_BENCHMARK=true test/sampling_benchmark_test.dart
// These Flutter-test debug timings are comparative, not production performance.
void main() {
  test(
    'records sampling error and debug construction cost',
    () async {
      const curves = <String, Curve>{
        'default_easeInOut': Curves.easeInOut,
        'quint': Curves.easeInOutQuint,
        'elastic': Curves.elasticOut,
      };
      const pairs =
          <({String name, Color from, Color to, EasingColorSpace space})>[
            (
              name: 'black_alpha_fade',
              from: Color(0xFF000000),
              to: Color(0x00000000),
              space: EasingColorSpace.oklab,
            ),
            (
              name: 'white_hidden_rgb_fade',
              from: Color(0xFFFFFFFF),
              to: Color(0x00000000),
              space: EasingColorSpace.linearRgb,
            ),
            (
              name: 'chromatic_blue_yellow',
              from: Color(0xFF2563EB),
              to: Color(0xFFFACC15),
              space: EasingColorSpace.oklab,
            ),
            (
              name: 'polar_oklch_alpha',
              from: Color(0x444F46E5),
              to: Color(0xFFF97316),
              space: EasingColorSpace.oklch,
            ),
            (
              name: 'polar_hsl_chromatic',
              from: Color(0xFFEF4444),
              to: Color(0xFF2563EB),
              space: EasingColorSpace.hsl,
            ),
          ];
      const batches = 7;
      const iterations = 20;
      const positions = 4097;
      final rows = <Map<String, Object?>>[];
      var sink = 0.0;
      for (final pair in pairs) {
        for (final curve in curves.entries) {
          for (final samples in [15, 31, 63]) {
            for (final strategy in SamplingStrategy.values) {
              EasedColorStops construct() => sampleGradient(
                from: pair.from,
                to: pair.to,
                curve: curve.value,
                space: pair.space,
                samples: samples,
                strategy: strategy,
              );
              final generated = construct();
              final error = measureSamplingError(
                from: pair.from,
                to: pair.to,
                curve: curve.value,
                space: pair.space,
                generated: generated,
                positions: positions,
              );
              expect([
                error.maximum,
                error.p95,
                error.rms,
              ], everyElement(inInclusiveRange(0, 1)));
              for (var i = 0; i < 20; i++) {
                sink += construct().colors.length;
              }
              final timings = <double>[];
              for (var batch = 0; batch < batches; batch++) {
                final stopwatch = Stopwatch()..start();
                for (var i = 0; i < iterations; i++) {
                  final result = construct();
                  sink +=
                      result.colors[result.colors.length ~/ 2].r +
                      result.stops.length;
                }
                stopwatch.stop();
                timings.add(stopwatch.elapsedMicroseconds / iterations);
              }
              timings.sort();
              rows.add({
                'pair': pair.name,
                'from_argb': pair.from.toARGB32(),
                'to_argb': pair.to.toARGB32(),
                'space': pair.space.name,
                'curve': curve.key,
                'strategy': strategy.name,
                'effective_strategy':
                    strategy == SamplingStrategy.bezier && curve.value is! Cubic
                    ? SamplingStrategy.uniform.name
                    : strategy.name,
                'interior_budget': samples,
                'distinct_positions': generated.stops.toSet().length,
                'total_stops_including_guards': generated.stops.length,
                'error': {
                  'maximum': error.maximum,
                  'p95': error.p95,
                  'rms': error.rms,
                },
                'construction_debug_us': {
                  'samples_per_operation': timings,
                  'median': timings[timings.length ~/ 2],
                  'mean': timings.reduce((a, b) => a + b) / timings.length,
                  'batches': batches,
                  'iterations_per_batch': iterations,
                },
              });
            }
          }
        }
      }
      final output = File('build/performance/sampling.json');
      await output.parent.create(recursive: true);
      await output.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'schema_version': 1,
          'timing_context':
              'Flutter test debug/JIT; nonproduction, not frame or GPU timings',
          'timed_operation':
              'construction plus one color-channel and stop-count read',
          'model': 'straight sRGB RGBA stops; max alpha/source-over channel error over black and white',
          'error_units':
              'normalized channels; multiply by 255 for 8-bit channel units',
          'error_reference_positions': positions,
          'scope': 'CPU stop placement only; not independent mixer validation or display quality',
          'operating_system': Platform.operatingSystem,
          'dart_version': Platform.version,
          'sink': sink,
          'results': rows,
        }),
      );
      expect(rows, hasLength(135));
      expect(await output.exists(), isTrue);
    },
    skip: !const bool.fromEnvironment('SAMPLING_BENCHMARK')
        ? 'Opt in with --dart-define=SAMPLING_BENCHMARK=true.'
        : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
