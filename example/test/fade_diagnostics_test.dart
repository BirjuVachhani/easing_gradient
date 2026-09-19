import 'dart:ui' as ui;

import 'package:easing_gradient_example/accuracy_lab_page.dart';
import 'package:easing_gradient_example/main.dart';
import 'package:easing_gradient_example/src/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('CPU reference covers every physical pixel exactly once', () async {
    for (final dpr in [1.0, 1.5, 2.0]) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(dpr);
      const size = Size(32, 8);
      const foreground = Color.from(alpha: 0.5, red: 0, green: 0, blue: 0);
      ReferenceStripPainter(
        evaluate: (_) => foreground,
        background: Colors.white,
        devicePixelRatio: dpr,
      ).paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (32 * dpr).round(),
        (8 * dpr).round(),
      );
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      for (var i = 0; i < data.lengthInBytes; i += 4) {
        expect(
          data.getUint8(i),
          closeTo(128, 1),
          reason: 'No gaps or overlapping alpha at DPR $dpr.',
        );
        expect(data.getUint8(i + 3), 255);
      }
      image.dispose();
      picture.dispose();
    }
  });

  testWidgets('accuracy controls change presets and placement', (tester) async {
    useDesktopViewport(tester, size: const Size(1600, 1800));
    await tester.pumpWidget(const EasingGradientDemo());
    await openPage(tester, SitePage.accuracy);
    expect(find.text('Black fade on white'), findsOneWidget);
    expect(find.text('MODEL ERROR (x255)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('accuracy-preset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('White fade on black').last);
    await tester.pumpAndSettle();
    expect(find.text('White fade on black'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('accuracy-strategy')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bezier').last);
    await tester.pumpAndSettle();
    expect(find.text('bezier native'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('alpha shader pins endpoints and adds bounded spatial noise', () async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/alpha_fade.frag',
    );
    final shader = program.fragmentShader();
    const width = 32;
    const height = 512;
    Future<List<int>> render(double dither) async {
      shader
        ..setFloat(0, width.toDouble())
        ..setFloat(1, height.toDouble())
        ..setFloat(2, 1)
        ..setFloat(3, 0.5)
        ..setFloat(4, 0.42)
        ..setFloat(5, 0)
        ..setFloat(6, 0.58)
        ..setFloat(7, 1)
        ..setFloat(8, dither);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 32, 512),
        Paint()..shader = shader,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final alpha = [
        for (var i = 3; i < bytes.lengthInBytes; i += 4) bytes.getUint8(i),
      ];
      image.dispose();
      picture.dispose();
      return alpha;
    }

    final plain = await render(0);
    final dithered = await render(1);
    final repeated = await render(1);
    expect(
      repeated,
      dithered,
      reason: 'Stationary masks must not shimmer over time.',
    );
    expect(plain.first, 0);
    expect(plain.last, 0);
    expect(plain[256 * width], 255);
    var changed = 0;
    for (var i = 0; i < plain.length; i++) {
      expect((plain[i] - dithered[i]).abs(), lessThanOrEqualTo(1));
      if (plain[i] != dithered[i]) changed++;
    }
    expect(
      changed,
      greaterThan(0),
      reason: 'The diagnostic must alter alpha, not just discarded RGB.',
    );
    shader.dispose();
  });
}
