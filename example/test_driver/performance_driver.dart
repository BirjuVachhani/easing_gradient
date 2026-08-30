import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Receives `reportData` from the device integration test and persists it.
///
/// Run this driver from `example/`. The generated JSON is intentionally placed
/// under `build/`, so it is a local artifact ignored by version control. Copy a
/// result elsewhere before cleaning build output if it must be retained.
Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      final outputDirectory = Directory('build/performance');
      await outputDirectory.create(recursive: true);
      final output = File('${outputDirectory.path}/gradient_benchmark.json');
      await output.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );
      // ignore: avoid_print
      print('Benchmark data written to ${output.absolute.path}');
    },
  );
}
