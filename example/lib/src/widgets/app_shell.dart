import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme_controller.dart';
import '../theme/tokens.dart';
import 'section.dart';

/// The site's top-level destinations, in nav order.
enum SitePage {
  home('Home', 'home'),
  docs('Docs', 'docs'),
  examples('Examples', 'examples'),
  compare('Compare', 'compare'),
  edgeFade('Edge fade', 'edge-fade'),
  playground('Playground', 'playground'),
  accuracy('Accuracy', 'accuracy');

  const SitePage(this.label, this.slug);

  /// Nav link text.
  final String label;

  /// Stable id used for widget keys, so tests target a link and never collide
  /// with the identically named heading on the page it opens.
  final String slug;

  /// The browser path this destination lives at.
  String get path => this == home ? '/' : '/$slug';

  Key get navKey => ValueKey('nav-$slug');

  /// The destination [location] addresses, or null when nothing matches.
  static SitePage? forLocation(String location) {
    // Trailing slashes come back from hand-typed and copied URLs.
    final normalized = location.length > 1 && location.endsWith('/')
        ? location.substring(0, location.length - 1)
        : location;
    for (final page in values) {
      if (page.path == normalized) return page;
    }
    return null;
  }
}

/// Page scaffold shared by every destination: a pinned top [_NavBar] over a
/// full-bleed body that scrolls behind it.
///
/// The body is rebuilt per destination rather than kept in an [IndexedStack], so
/// each page starts at the top and heavy gradient pages are not retained while
/// hidden.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.current, required this.child});

  /// The destination the current URL resolves to, or null on an unknown path.
  final SitePage? current;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Whether the page has scrolled off the top. Drives the nav's bottom border,
  /// which fades in on scroll. Kept in a notifier so only the nav rebuilds.
  final ValueNotifier<bool> _scrolled = ValueNotifier<bool>(false);

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) _scrolled.value = false;
  }

  @override
  void dispose() {
    _scrolled.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    // Only the page's own vertical scroll, not nested scrollers inside demos.
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final scrolled = notification.metrics.pixels > 0.5;
      if (scrolled != _scrolled.value) _scrolled.value = scrolled;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.child,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _NavBar(current: widget.current, scrolled: _scrolled),
          ),
        ],
      ),
    );
  }
}

/// The sticky top navigation: wordmark on the left, destination links and
/// controls on the right. Below [AppLayout.compactBreakpoint] the links collapse
/// into a menu button.
class _NavBar extends StatelessWidget {
  const _NavBar({required this.current, required this.scrolled});

  final SitePage? current;
  final ValueListenable<bool> scrolled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final compact = context.isCompact;

    final row = ContentContainer(
      child: Row(
        children: [
          Expanded(child: _Brand(onTap: () => context.go(SitePage.home.path))),
          if (!compact) ...[
            for (final page in SitePage.values)
              _NavLink(
                key: page.navKey,
                label: page.label,
                path: page.path,
                active: page == current,
              ),
            const _NavDivider(),
            const _ThemeToggle(),
          ] else ...[
            const _ThemeToggle(),
            _IconAction(
              key: const ValueKey('nav-menu'),
              icon: Icons.menu_rounded,
              tooltip: 'Menu',
              onTap: () => _showNavSheet(context, current),
            ),
          ],
        ],
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: scrolled,
      builder: (context, isScrolled, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppLayout.navHeight,
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(
            bottom: BorderSide(
              color: isScrolled ? colors.border : Colors.transparent,
            ),
          ),
        ),
        child: child,
      ),
      child: row,
    );
  }
}

Future<void> _showNavSheet(BuildContext context, SitePage? current) {
  final colors = context.colors;
  // The sheet's own context dies with the sheet, so navigation goes through
  // the router held by the context that opened it.
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      side: BorderSide(color: colors.border),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final page in SitePage.values)
            ListTile(
              key: ValueKey('sheet-${page.slug}'),
              title: Text(
                page.label,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 15,
                  fontWeight: page == current
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
              trailing: page == current
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: colors.foreground,
                    )
                  : null,
              onTap: () {
                Navigator.of(sheetContext).pop();
                router.go(page.path);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// The wordmark: a monospace package name that returns to the first page.
class _Brand extends StatefulWidget {
  const _Brand({this.onTap});

  final VoidCallback? onTap;

  @override
  State<_Brand> createState() => _BrandState();
}

class _BrandState extends State<_Brand> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'easing_gradient',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                  color: _hovered
                      ? colors.foreground.withValues(alpha: 0.8)
                      : colors.foreground,
                ),
              ),
              if (!context.isCompact) ...[
                const SizedBox(width: 10),
                // Flexible so the tagline gives way under pressure instead of
                // pushing the nav links past the right edge.
                Flexible(
                  child: Text(
                    'gradients shaped by any Curve',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A button-styled nav link: the active destination is foreground and medium
/// weight, the rest are muted and brighten on hover over a subtle pill.
class _NavLink extends StatefulWidget {
  const _NavLink({
    super.key,
    required this.label,
    required this.path,
    this.active = false,
  });

  final String label;

  /// Router path this link navigates to.
  final String path;
  final bool active;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = widget.active || _hovered
        ? colors.foreground
        : colors.mutedForeground;
    return SelectionContainer.disabled(
      child: Semantics(
        link: true,
        label: widget.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go(widget.path),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hovered
                    ? colors.foreground.withValues(alpha: 0.07)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: widget.active ? FontWeight.w500 : FontWeight.w400,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The thin vertical rule between the links and the icon buttons.
class _NavDivider extends StatelessWidget {
  const _NavDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: context.colors.border,
  );
}

/// A square icon button with a rounded hover pill.
class _IconAction extends StatefulWidget {
  const _IconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SelectionContainer.disabled(
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hovered
                    ? colors.foreground.withValues(alpha: 0.07)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(widget.icon, size: 18, color: colors.foreground),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = AppTheme.of(context);
    return _IconAction(
      key: const ValueKey('nav-theme-toggle'),
      icon: controller.isDark
          ? Icons.light_mode_outlined
          : Icons.dark_mode_outlined,
      tooltip: controller.isDark ? 'Light mode' : 'Dark mode',
      onTap: controller.toggle,
    );
  }
}

/// A minimal footer: the package name, a one-line credit, and the source links.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: ContentContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Text(
                'easing_gradient',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Drop-in easing versions of Flutter gradients, sampled once and '
                'painted by the native shader.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedForeground, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: const [
                  AppBadge('Flutter 3.47.1+', mono: true),
                  AppBadge('BSD 3-Clause'),
                  AppBadge('No dependencies'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
