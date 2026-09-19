import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Centers its [child] in a column no wider than [maxWidth], with a constant
/// gutter at every breakpoint.
///
/// This is what keeps the site from stretching gradient strips across an
/// ultrawide window, and what aligns every section to the same left edge.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    const gutter = 20.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + gutter * 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: gutter),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// A vertically padded page section inside a [ContentContainer].
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
    this.top,
    this.bottom,
    this.background,
    this.border = false,
  });

  final Widget child;
  final double maxWidth;
  final double? top;
  final double? bottom;
  final Color? background;

  /// Draw a hairline divider on top of the section.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final v = context.isCompact ? 48.0 : 72.0;
    Widget content = Padding(
      padding: EdgeInsets.only(top: top ?? v, bottom: bottom ?? v),
      child: ContentContainer(maxWidth: maxWidth, child: child),
    );
    if (background != null || border) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: border
              ? Border(top: BorderSide(color: context.colors.border))
              : null,
        ),
        child: content,
      );
    }
    return content;
  }
}

/// A page title over a muted standfirst, capped to a reading column.
class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final compact = context.isCompact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.foreground,
            fontSize: compact ? 32 : 44,
            fontWeight: FontWeight.w600,
            height: 1.1,
            letterSpacing: compact ? -0.8 : -1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.readingMaxWidth,
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: compact ? 15 : 17,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A section title with an optional subtitle, one step down from [PageHeading].
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.readingMaxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A bordered surface card, the standard container for a demo or control block.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

/// A small static label chip.
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.mono = false});

  final String label;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.mutedForeground,
          fontFamily: mono ? AppFonts.mono : AppFonts.sans,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
