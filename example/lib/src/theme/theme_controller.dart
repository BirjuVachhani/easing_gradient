import 'package:flutter/material.dart';

/// Holds the active [ThemeMode] and notifies listeners when it changes.
///
/// Dark is the default. Gradients are judged against both, so the toggle is a
/// first-class control rather than a system-only preference. State is in memory.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.value = ThemeMode.dark]);

  bool get isDark => value == ThemeMode.dark;

  void toggle() => value = isDark ? ThemeMode.light : ThemeMode.dark;
}

/// Exposes a [ThemeController] to descendants and rebuilds them when the mode
/// changes. Access through `AppTheme.of(context)`.
class AppTheme extends InheritedNotifier<ThemeController> {
  const AppTheme({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(scope != null, 'AppTheme.of() called with no AppTheme in the tree.');
    return scope!.notifier!;
  }
}
