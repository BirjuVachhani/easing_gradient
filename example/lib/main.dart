import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

import 'accuracy_lab_page.dart';
import 'comparison_page.dart';
import 'docs_page.dart';
import 'edge_fade_page.dart';
import 'examples_page.dart';
import 'home_page.dart';
import 'playground_page.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/theme_controller.dart';
import 'src/widgets/app_shell.dart';

void main() {
  // Clean URLs on the web: /docs instead of /#/docs.
  usePathUrlStrategy();
  // Tokenize off the UI thread on every platform: a code block paints in the
  // theme's base color immediately and swaps to the highlighted spans when
  // tokenization finishes, so the one-time grammar compile never blocks a
  // frame. Pierre is the site-wide pair, matching shiki.birju.dev.
  ShikiHighlighter.config = const ShikiHighlighterConfig(
    asyncIO: true,
    asyncWeb: true,
    defaultTheme: ShikiDualTheme(
      light: PierreThemes.pierreLight,
      dark: PierreThemes.pierreDark,
    ),
  );
  runApp(const EasingGradientDemo());
}

/// Builds one shell-wrapped route per [SitePage].
///
/// Every destination lives in the same [AppShell] so the nav stays put while
/// the body swaps. NoTransitionPage, because a website changes pages, it does
/// not slide between them.
///
/// A function rather than a global, so each app instance (and each widget
/// test) starts at its own location instead of wherever the last one ended.
GoRouter buildRouter() => GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        final page = SitePage.forLocation(state.uri.path);
        return AppShell(
          current: page,
          // Keyed so switching destinations rebuilds from a fresh scroll
          // offset instead of restoring the previous page's position.
          child: KeyedSubtree(key: ValueKey(page), child: child),
        );
      },
      routes: [
        for (final page in SitePage.values)
          GoRoute(
            path: page.path,
            pageBuilder: (context, state) => NoTransitionPage(
              name: page.label,
              child: switch (page) {
                SitePage.home => const HomePage(),
                SitePage.docs => const DocsPage(),
                SitePage.examples => const ExamplesPage(),
                SitePage.compare => const ComparisonPage(),
                SitePage.edgeFade => const EdgeFadePage(),
                SitePage.playground => const PlaygroundPage(),
                SitePage.accuracy => const AccuracyLabPage(),
              },
            ),
          ),
      ],
    ),
  ],
  // A mistyped or stale URL lands on the home page rather than an error
  // screen; the address bar is rewritten so the state stays shareable.
  onException: (context, state, router) => router.go(SitePage.home.path),
);

/// Root of the showcase site. Owns the [ThemeController] and rebuilds the app
/// when the light/dark mode changes.
class EasingGradientDemo extends StatefulWidget {
  const EasingGradientDemo({super.key});

  @override
  State<EasingGradientDemo> createState() => _EasingGradientDemoState();
}

class _EasingGradientDemoState extends State<EasingGradientDemo> {
  final ThemeController _theme = ThemeController();
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme(
      controller: _theme,
      child: ListenableBuilder(
        listenable: _theme,
        builder: (context, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'easing_gradient: silky smooth Flutter gradients',
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: _theme.value,
          routerConfig: _router,
        ),
      ),
    );
  }
}
