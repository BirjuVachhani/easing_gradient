import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiki_flutter/shiki_flutter.dart';

import '../highlight/highlighter.dart';
import '../theme/tokens.dart';

/// A rounded, bordered code card highlighted by shiki_flutter in the Pierre
/// theme pair, following the site's light/dark mode.
///
/// The block grows to fit its content vertically so it never traps the page's
/// scroll; long lines scroll horizontally instead.
class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.code,
    this.language = 'dart',
    this.filename,
    this.showLineNumbers = true,
    this.fontSize = 13,
  });

  final String code;
  final String language;

  /// When set, renders a header bar with this file name and the copy button.
  /// Without one, a small copy chip floats over the code instead.
  final String? filename;

  final bool showLineNumbers;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final service = SiteHighlighter.instance;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final ShikiTheme resolved = SiteHighlighter.theme.resolve(isDark: isDark);

    final trimmed = code.trim();
    final background = service.backgroundOf(resolved.id, colors.surface);
    final onBackground = background.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    final border = onBackground.withValues(alpha: 0.10);

    // Highlighting is asynchronous: the plain code paints first and swaps to
    // the highlighted spans when tokenization finishes. No wrapping
    // SelectionArea here, because every page already provides one and nesting
    // them breaks keyboard copy.
    final Widget body = ShikiCodeView(
      highlighter: service.highlighter,
      code: trimmed,
      lang: SiteHighlighter.languageFor(language),
      theme: resolved,
      selectable: true,
      textStyle: TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: fontSize,
        height: 20 / fontSize,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      gutterStyle: GutterStyle(
        spacing: 15.6,
        textColor: onBackground.withValues(alpha: 0.32),
        textScale: 0.9,
      ),
      showLineNumbers: showLineNumbers,
      paintBackground: false,
      padding: EdgeInsets.only(
        left: 15.6,
        top: filename != null ? 0 : 12,
        bottom: 12,
        right: 15.6,
      ),
    );

    final Widget content = filename != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                filename: filename!,
                onBackground: onBackground,
                copyText: trimmed,
              ),
              body,
            ],
          )
        : Stack(
            children: [
              body,
              Positioned(
                top: 8,
                right: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      onBackground.withValues(alpha: 0.06),
                      background,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: onBackground.withValues(alpha: 0.10),
                    ),
                  ),
                  child: CopyButton(text: trimmed, onBackground: onBackground),
                ),
              ),
            ],
          );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: border),
      ),
      child: content,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.filename,
    required this.onBackground,
    required this.copyText,
  });

  final String filename;
  final Color onBackground;
  final String copyText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: Row(
          children: [
            Icon(
              Icons.code_rounded,
              size: 16,
              color: onBackground.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectionContainer.disabled(
                child: Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                    height: 1,
                    color: onBackground,
                  ),
                ),
              ),
            ),
            CopyButton(text: copyText, onBackground: onBackground),
          ],
        ),
      ),
    );
  }
}

/// Copies [text] and briefly shows a checkmark.
///
/// [onBackground] keeps the glyph legible when a light-themed block sits in a
/// dark page, or the reverse.
class CopyButton extends StatefulWidget {
  const CopyButton({super.key, required this.text, required this.onBackground});

  final String text;
  final Color onBackground;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;
  bool _hovered = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _copied
        ? context.colors.accent
        : widget.onBackground.withValues(alpha: _hovered ? 1 : 0.55);
    return SelectionContainer.disabled(
      child: Tooltip(
        message: _copied ? 'Copied' : 'Copy',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _copy,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 15,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
