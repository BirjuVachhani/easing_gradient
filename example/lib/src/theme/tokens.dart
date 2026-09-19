import 'package:flutter/material.dart';

/// The site's semantic color palette, exposed as a [ThemeExtension] so any
/// widget can read tokens through `context.colors`.
///
/// The scale is the shadcn/ui "neutral" system: monochrome chrome with hairline
/// borders, so the gradient previews are the only saturated color on screen.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceInset,
    required this.border,
    required this.borderStrong,
    required this.foreground,
    required this.mutedForeground,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.link,
    required this.shadow,
  });

  /// Page background.
  final Color background;

  /// Card or raised surface.
  final Color surface;

  /// Inset surface for chips, control rows, and preview mats.
  final Color surfaceInset;

  /// Hairline border.
  final Color border;

  /// Slightly stronger border for emphasis.
  final Color borderStrong;

  /// Primary text color.
  final Color foreground;

  /// Secondary, de-emphasized text.
  final Color mutedForeground;

  /// Solid button background.
  final Color primary;

  /// Text and icon color on top of [primary].
  final Color onPrimary;

  /// Sparingly used success accent.
  final Color accent;

  /// Link and interactive accent.
  final Color link;

  /// Shadow under floating cards.
  final Color shadow;

  static const AppColors dark = AppColors(
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    surfaceInset: Color(0xFF262626),
    border: Color(0x1AFFFFFF),
    borderStrong: Color(0xFF2A2A2A),
    foreground: Color(0xFFFAFAFA),
    mutedForeground: Color(0xFFA1A1A1),
    primary: Color(0xFFFAFAFA),
    onPrimary: Color(0xFF0A0A0A),
    accent: Color(0xFF34D399),
    link: Color(0xFF7AA2F7),
    shadow: Color(0x66000000),
  );

  static const AppColors light = AppColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceInset: Color(0xFFF5F5F5),
    border: Color(0xFFE6E6E6),
    borderStrong: Color(0xFFD4D4D4),
    foreground: Color(0xFF0A0A0A),
    mutedForeground: Color(0xFF6B6B6B),
    primary: Color(0xFF171717),
    onPrimary: Color(0xFFFAFAFA),
    accent: Color(0xFF059669),
    link: Color(0xFF2563EB),
    shadow: Color(0x14000000),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceInset,
    Color? border,
    Color? borderStrong,
    Color? foreground,
    Color? mutedForeground,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? link,
    Color? shadow,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceInset: surfaceInset ?? this.surfaceInset,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      link: link ?? this.link,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceInset: Color.lerp(surfaceInset, other.surfaceInset, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      link: Color.lerp(link, other.link, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Corner radii used across the site.
abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double pill = 999;
}

/// Layout constants.
abstract final class AppLayout {
  /// Max width of a standard content column.
  static const double contentMaxWidth = 1240;

  /// Max width of a reading column, used for prose.
  static const double readingMaxWidth = 780;

  /// Height of the sticky top navigation bar.
  static const double navHeight = 60;

  /// Below this width the layout collapses to one column and the nav links
  /// move into a menu.
  static const double compactBreakpoint = 900;
}

/// Font families declared in `pubspec.yaml`.
abstract final class AppFonts {
  static const String sans = 'Geist';
  static const String mono = 'Geist Mono';
}

extension AppColorsContext on BuildContext {
  /// The active [AppColors] for this subtree.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// Whether the compact layout should be used.
  bool get isCompact =>
      MediaQuery.sizeOf(this).width < AppLayout.compactBreakpoint;
}
