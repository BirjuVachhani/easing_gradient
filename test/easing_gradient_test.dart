import 'dart:math' as math;

import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Protects the package's drop-in Flutter subtype contract: geometry forwarding,
// shader creation, configuration equality, inherited-operation type downgrade,
// and rendering inside a real BoxDecoration.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sourceColors = <Color>[Color(0xFF4F46E5), Color(0x00F97316)];

  test('linear gradient is a drop-in LinearGradient and creates a shader', () {
    final gradient = EasingLinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: sourceColors,
      tileMode: TileMode.mirror,
      transform: const GradientRotation(0.5),
    );
    expect(gradient, isA<LinearGradient>());
    expect(gradient, isA<Gradient>());
    expect(gradient.begin, Alignment.topLeft);
    expect(gradient.end, Alignment.bottomRight);
    expect(gradient.tileMode, TileMode.mirror);
    expect(gradient.sourceColors, sourceColors);
    expect(gradient.colors.length, 18);
    expect(
      gradient.createShader(const Rect.fromLTWH(0, 0, 100, 100)),
      isA<Shader>(),
    );
  });

  test('radial gradient passes all geometry through', () {
    final gradient = EasingRadialGradient(
      center: Alignment.topRight,
      radius: 0.8,
      focal: Alignment.bottomLeft,
      focalRadius: 0.1,
      colors: sourceColors,
      tileMode: TileMode.repeated,
    );
    expect(gradient, isA<RadialGradient>());
    expect(gradient.center, Alignment.topRight);
    expect(gradient.radius, 0.8);
    expect(gradient.focal, Alignment.bottomLeft);
    expect(gradient.focalRadius, 0.1);
    expect(gradient.tileMode, TileMode.repeated);
    expect(
      gradient.createShader(const Rect.fromLTWH(0, 0, 100, 100)),
      isA<Shader>(),
    );
  });

  test('sweep gradient passes all geometry through', () {
    final gradient = EasingSweepGradient(
      center: Alignment.centerRight,
      startAngle: math.pi / 4,
      endAngle: math.pi,
      colors: sourceColors,
      tileMode: TileMode.decal,
    );
    expect(gradient, isA<SweepGradient>());
    expect(gradient.center, Alignment.centerRight);
    expect(gradient.startAngle, math.pi / 4);
    expect(gradient.endAngle, math.pi);
    expect(gradient.tileMode, TileMode.decal);
    expect(
      gradient.createShader(const Rect.fromLTWH(0, 0, 100, 100)),
      isA<Shader>(),
    );
  });

  test('identical easing gradients compare equal', () {
    final a = EasingLinearGradient(colors: sourceColors);
    final b = EasingLinearGradient(colors: sourceColors);
    final different = EasingLinearGradient(
      colors: sourceColors,
      curve: Curves.easeIn,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(different));

    final flatA = EasingLinearGradient(
      colors: const [Color(0xFF808080), Color(0xFF808080)],
      curve: Curves.linear,
    );
    final flatB = EasingLinearGradient(
      colors: const [Color(0xFF808080), Color(0xFF808080)],
      curve: Curves.easeInOut,
    );
    expect(
      flatA,
      isNot(flatB),
      reason:
          'Public easing configuration participates in value equality even '
          'when two configurations happen to paint the same flat gradient.',
    );
  });

  test('base-class operations preserve generated stops', () {
    final a = EasingLinearGradient(colors: sourceColors);
    final b = EasingLinearGradient(
      colors: const [Color(0xFF10B981), Color(0x00FFFFFF)],
      curve: Curves.easeOut,
      samplesPerTransition: 31,
    );
    final faded = a.withOpacity(0.5);
    expect(faded, isA<LinearGradient>());
    expect(faded.stops, a.stops);

    final middle = LinearGradient.lerp(a, b, 0.5);
    expect(middle, isNotNull);
    expect(middle, isA<LinearGradient>());
    expect(middle!.colors.length, greaterThanOrEqualTo(a.colors.length));
  });

  testWidgets('renders inside BoxDecoration without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DecoratedBox(
          decoration: BoxDecoration(
            gradient: EasingLinearGradient(colors: sourceColors),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
