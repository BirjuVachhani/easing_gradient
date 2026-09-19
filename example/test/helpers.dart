import 'package:easing_gradient_example/src/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens a destination through the real navigation: the top links on wide
/// viewports, or the menu sheet once they collapse.
///
/// Tests target the nav by key rather than by label because several
/// destinations share a name with the heading on the page they open.
Future<void> openPage(WidgetTester tester, SitePage page) async {
  final link = find.byKey(page.navKey);
  if (link.evaluate().isNotEmpty) {
    await tester.tap(link);
  } else {
    await tester.tap(find.byKey(const ValueKey('nav-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('sheet-${page.slug}')));
  }
  await tester.pumpAndSettle();
}

/// Sizes the test view to a desktop window, where the nav shows every link.
void useDesktopViewport(
  WidgetTester tester, {
  Size size = const Size(1440, 1200),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
