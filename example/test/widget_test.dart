import 'package:easing_gradient_example/main.dart';
import 'package:easing_gradient_example/src/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

// Covers site navigation, lazy catalog completeness, the catalog's custom
// 700-pixel card breakpoint, and the nav's own compact breakpoint. The 390 and
// 1200 logical-pixel viewports represent stacked and side-by-side preview
// layouts rather than specific devices.
void main() {
  testWidgets('the top nav reaches every destination', (tester) async {
    useDesktopViewport(tester);
    await tester.pumpWidget(const EasingGradientDemo());

    // Home is the landing destination.
    // textContaining, so tuning where the headline wraps does not break this.
    expect(find.textContaining('Take the hard edge'), findsOneWidget);

    await openPage(tester, SitePage.docs);
    expect(find.text('Introduction'), findsWidgets);

    await openPage(tester, SitePage.examples);
    expect(find.text('From the web'), findsOneWidget);

    await openPage(tester, SitePage.compare);
    expect(find.text('Gradient comparison gallery'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('compare-section-basics')),
      findsOneWidget,
    );

    await openPage(tester, SitePage.edgeFade);
    expect(
      find.byKey(const ValueKey('edge-fade-preview-eased-paragraphs')),
      findsOneWidget,
    );

    await openPage(tester, SitePage.playground);
    expect(find.text('Playground'), findsWidgets);

    await openPage(tester, SitePage.accuracy);
    expect(find.text('Accuracy Lab'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('below the nav breakpoint the links move into a menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EasingGradientDemo());
    expect(find.byKey(SitePage.compare.navKey), findsNothing);
    expect(find.byKey(const ValueKey('nav-menu')), findsOneWidget);

    await openPage(tester, SitePage.compare);
    expect(find.text('Gradient comparison gallery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the theme toggle switches the site between dark and light', (
    tester,
  ) async {
    useDesktopViewport(tester);
    await tester.pumpWidget(const EasingGradientDemo());

    Color background() =>
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor!;
    final dark = background();

    await tester.tap(find.byKey(const ValueKey('nav-theme-toggle')));
    await tester.pumpAndSettle();
    expect(background(), isNot(dark));
    expect(tester.takeException(), isNull);
  });

  // The comparison preview only appears once the switch is on, so its presence
  // is what proves the second mask is actually built rather than just labelled.
  testWidgets('edge fade compares an eased mask against a linear one', (
    tester,
  ) async {
    useDesktopViewport(tester, size: const Size(1200, 1400));
    await tester.pumpWidget(const EasingGradientDemo());
    await openPage(tester, SitePage.edgeFade);

    // Paragraphs is the default content.
    final eased = find.byKey(
      const ValueKey('edge-fade-preview-eased-paragraphs'),
    );
    final linear = find.byKey(
      const ValueKey('edge-fade-preview-linear-paragraphs'),
    );
    expect(eased, findsOneWidget);
    expect(linear, findsNothing);
    expect(find.byType(ShaderMask), findsNWidgets(2));

    await tester.tap(find.text('Compare against a linear mask'));
    await tester.pumpAndSettle();
    expect(linear, findsOneWidget);
    expect(find.byType(ShaderMask), findsNWidgets(4));

    // Switching to the list swaps the phone content, keeping both masks.
    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('edge-fade-preview-eased-list')),
      findsOneWidget,
    );
    expect(find.byType(ShaderMask), findsNWidgets(4));

    await tester.tap(find.text('Fade edges'));
    await tester.pumpAndSettle();
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog reaches every section and final case', (tester) async {
    useDesktopViewport(tester);
    await tester.pumpWidget(const EasingGradientDemo());
    await openPage(tester, SitePage.compare);
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
    await openPage(tester, SitePage.compare);
    final left = find.byKey(const ValueKey('compare-case-photo-scrim-left'));
    final right = find.byKey(const ValueKey('compare-case-photo-scrim-right'));
    expect(
      tester.getTopLeft(right).dy,
      greaterThan(tester.getTopLeft(left).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide comparison pairs share a row', (tester) async {
    useDesktopViewport(tester, size: const Size(1200, 900));
    await tester.pumpWidget(const EasingGradientDemo());
    await openPage(tester, SitePage.compare);
    final left = find.byKey(const ValueKey('compare-case-photo-scrim-left'));
    final right = find.byKey(const ValueKey('compare-case-photo-scrim-right'));
    expect(tester.getTopLeft(right).dy, closeTo(tester.getTopLeft(left).dy, 1));
    expect(
      tester.getTopLeft(right).dx,
      greaterThan(tester.getTopLeft(left).dx),
    );
    expect(tester.takeException(), isNull);
  });
}
