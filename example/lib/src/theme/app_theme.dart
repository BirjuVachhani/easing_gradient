import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the [ThemeData] for a [brightness], wiring in the [AppColors]
/// extension, the Geist UI font, and a neutral, low-chrome Material baseline.
///
/// Material's stock controls carry Material-app defaults (tall filled inputs,
/// pill sliders, heavy ripples) that read as an Android app inside a website.
/// The component themes below flatten them into the same bordered, hairline
/// surfaces the rest of the site uses, so the pages stay plain Material while
/// the chrome looks like a site.
ThemeData buildTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: colors.foreground,
        brightness: brightness,
      ).copyWith(
        surface: colors.background,
        onSurface: colors.foreground,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        outline: colors.border,
      );

  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    fontFamily: AppFonts.sans,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: colors.foreground.withValues(alpha: 0.04),
  );

  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.sm),
    borderSide: BorderSide(color: color),
  );

  return base.copyWith(
    extensions: [colors],
    textTheme: _textTheme(base.textTheme, colors),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.foreground,
      selectionColor: colors.link.withValues(alpha: 0.28),
      selectionHandleColor: colors.link,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        final hovered =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.dragged);
        return colors.foreground.withValues(alpha: hovered ? 0.45 : 0.28);
      }),
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(8),
      crossAxisMargin: 3,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: colors.border),
      ),
      textStyle: TextStyle(
        color: colors.foreground,
        fontFamily: AppFonts.sans,
        fontSize: 12,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: colors.border),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.border,
      space: 1,
      thickness: 1,
    ),
    // Dense, bordered, transparent fields instead of Material's filled boxes.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border(colors.border),
      enabledBorder: border(colors.border),
      focusedBorder: border(colors.borderStrong),
      labelStyle: TextStyle(color: colors.mutedForeground, fontSize: 13),
      floatingLabelStyle: TextStyle(
        color: colors.mutedForeground,
        fontSize: 13,
      ),
      hintStyle: TextStyle(color: colors.mutedForeground, fontSize: 14),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(
        color: colors.foreground,
        fontFamily: AppFonts.sans,
        fontSize: 14,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(color: colors.border),
          ),
        ),
      ),
    ),
    // A thin track with a small round thumb, closer to a web range input than
    // Material 3's tall bar with stop indicators.
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: colors.foreground,
      inactiveTrackColor: colors.surfaceInset,
      thumbColor: colors.foreground,
      overlayColor: colors.foreground.withValues(alpha: 0.10),
      valueIndicatorColor: colors.surfaceInset,
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      trackGap: 0,
      padding: EdgeInsets.zero,
      thumbSize: const WidgetStatePropertyAll(Size(14, 14)),
      valueIndicatorTextStyle: TextStyle(
        color: colors.foreground,
        fontFamily: AppFonts.sans,
        fontSize: 12,
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.foreground
            : colors.surfaceInset,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.background
            : colors.mutedForeground,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.foreground
            : colors.border,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.foreground
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.background
              : colors.mutedForeground,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),
    ),
  );
}

TextTheme _textTheme(TextTheme base, AppColors colors) {
  TextStyle apply(TextStyle? style, {Color? color}) =>
      (style ?? const TextStyle()).copyWith(
        color: color ?? colors.foreground,
        fontFamily: AppFonts.sans,
      );
  return base
      .apply(fontFamily: AppFonts.sans)
      .copyWith(
        displayLarge: apply(base.displayLarge),
        displayMedium: apply(base.displayMedium),
        headlineLarge: apply(base.headlineLarge),
        headlineMedium: apply(base.headlineMedium)
            .copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.8),
        titleLarge: apply(base.titleLarge)
            .copyWith(fontWeight: FontWeight.w500, letterSpacing: -0.3),
        titleMedium: apply(base.titleMedium).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.1,
        ),
        bodyLarge: apply(
          base.bodyLarge,
          color: colors.mutedForeground,
        ).copyWith(fontSize: 16, height: 1.6),
        bodyMedium: apply(
          base.bodyMedium,
          color: colors.mutedForeground,
        ).copyWith(fontSize: 14, height: 1.6),
        bodySmall: apply(
          base.bodySmall,
          color: colors.mutedForeground,
        ).copyWith(fontSize: 13, height: 1.5),
        labelLarge: apply(base.labelLarge)
            .copyWith(fontSize: 13, fontWeight: FontWeight.w500),
      );
}
