import 'package:easing_gradient_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Covers app navigation, lazy catalog completeness, and the catalog's custom
// 700-pixel card breakpoint. The 390 and 1200 logical-pixel viewports represent
// stacked and side-by-side preview layouts rather than specific devices.
void main() {
  testWidgets('opens Compare, Playground and Accuracy', (tester) async {
    await tester.pumpWidget(const EasingGradientDemo());
    expect(find.text('Gradient comparison gallery'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('compare-section-basics')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('Playground'), findsWidgets);

    await tester.tap(find.byIcon(Icons.science));
    await tester.pumpAndSettle();
    expect(find.text('Accuracy Lab'), findsOneWidget);
  });

  testWidgets('catalog reaches every section and final case', (tester) async {
    await tester.pumpWidget(const EasingGradientDemo());
    final scrollable = find.byType(Scrollable).first;

    for (final id in [
      'basics',
      'color',
      'stops',
      'steps',
      'geometry',
      'density',
    ]) {
      final section = find.byKey(ValueKey('compare-section-$id'));
      await tester.scrollUntilVisible(section, 500, scrollable: scrollable);
      expect(section, findsOneWidget);
    }

    final finalCase = find.byKey(const ValueKey('compare-case-default-high'));
    await tester.scrollUntilVisible(finalCase, 500, scrollable: scrollable);
    expect(finalCase, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow comparison pairs stack vertically', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EasingGradientDemo());
    final left = find.byKey(const ValueKey('compare-case-classic-scrim-left'));
    final right = find.byKey(
      const ValueKey('compare-case-classic-scrim-right'),
    );
    expect(
      tester.getTopLeft(right).dy,
      greaterThan(tester.getTopLeft(left).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide comparison pairs share a row', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EasingGradientDemo());
    final left = find.byKey(const ValueKey('compare-case-classic-scrim-left'));
    final right = find.byKey(
      const ValueKey('compare-case-classic-scrim-right'),
    );
    expect(tester.getTopLeft(right).dy, closeTo(tester.getTopLeft(left).dy, 1));
    expect(
      tester.getTopLeft(right).dx,
      greaterThan(tester.getTopLeft(left).dx),
    );
    expect(tester.takeException(), isNull);
  });
}
