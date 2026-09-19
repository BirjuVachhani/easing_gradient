import 'package:flutter/material.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

/// The one shared [ShikiHighlighter] for the whole site.
///
/// Sharing matters: the highlighter compiles a grammar once and caches its
/// tokens, so every later block on the page renders from that cache instead of
/// paying the compile again.
class SiteHighlighter {
  SiteHighlighter._();

  static final SiteHighlighter instance = SiteHighlighter._();

  /// The Pierre light/dark pair, the same default the shiki_flutter site uses.
  static const ShikiThemeBase theme = ShikiDualTheme(
    light: PierreThemes.pierreLight,
    dark: PierreThemes.pierreDark,
  );

  // Bundled language and theme symbols are top-level finals rather than
  // constants, so these cannot be const lists.
  static final List<CodeLanguage> _languages = [
    CodeLanguages.dart,
    CodeLanguages.shellscript,
    CodeLanguages.yaml,
  ];

  static final Map<String, CodeLanguage> _byId = {
    for (final language in _languages) language.id: language,
    // Shiki names the shell grammar `shellscript`; snippets say `shell`.
    'shell': CodeLanguages.shellscript,
    'bash': CodeLanguages.shellscript,
  };

  /// The bundled language registered under [id], falling back to Dart because
  /// every snippet on this site is Dart unless it says otherwise.
  static CodeLanguage languageFor(String id) => _byId[id] ?? CodeLanguages.dart;

  late final ShikiHighlighter highlighter = ShikiHighlighter()
    ..preload(
      langs: _languages,
      themes: [PierreThemes.pierreLight, PierreThemes.pierreDark],
    );

  final Map<String, Color> _backgrounds = {};

  /// The editor background declared by [themeId], resolved once and cached.
  Color backgroundOf(String themeId, Color fallback) {
    return _backgrounds.putIfAbsent(themeId, () {
      return parseColor(highlighter.getThemeRegistration(themeId).bg) ??
          fallback;
    });
  }
}
