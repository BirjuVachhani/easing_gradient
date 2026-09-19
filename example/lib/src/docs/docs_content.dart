import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/code_block.dart';

/// The reading measure for prose. Code blocks can span the full content column.
const double kProseWidth = 768;

/// A body paragraph. Wrap inline code in backticks and bold in double asterisks.
class DocProse extends StatelessWidget {
  const DocProse(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kProseWidth),
        child: Text.rich(
          TextSpan(children: inlineSpans(text, colors)),
          style: TextStyle(
            color: colors.foreground,
            fontSize: 16,
            height: 1.65,
          ),
        ),
      ),
    );
  }
}

/// A second-level heading inside one docs section.
class DocH3 extends StatelessWidget {
  const DocH3(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: context.colors.foreground,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    ),
  );
}

/// A bulleted list; each item supports inline `code` and **bold**.
class DocBullets extends StatelessWidget {
  const DocBullets(this.items, {super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kProseWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 11,
                        left: 4,
                        right: 14,
                      ),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.mutedForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: inlineSpans(item, colors)),
                        style: TextStyle(
                          color: colors.foreground,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A borderless documentation table with horizontal row rules.
class DocTable extends StatelessWidget {
  const DocTable({super.key, required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 22),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 640,
            maxWidth: kProseWidth,
          ),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: colors.border),
              bottom: BorderSide(color: colors.border),
            ),
            columnWidths: const {0: IntrinsicColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.borderStrong),
                  ),
                ),
                children: [for (final h in headers) _cell(context, h, true)],
              ),
              for (final row in rows)
                TableRow(
                  children: [
                    for (final value in row) _cell(context, value, false),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String text, bool header) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 12, right: 24),
    child: Text.rich(
      TextSpan(children: inlineSpans(text, context.colors)),
      style: TextStyle(
        color: context.colors.foreground,
        fontSize: 14,
        height: 1.5,
        fontWeight: header ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
  );
}

/// A subtle bordered callout for a caveat or tip.
class DocNote extends StatelessWidget {
  const DocNote(this.text, {super.key, this.icon = Icons.info_outline_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kProseWidth),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: colors.mutedForeground),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(children: inlineSpans(text, colors)),
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: 14.5,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A documentation code block, highlighted by shiki_flutter in the Pierre
/// theme pair.
///
/// Thin wrapper over [CodeBlock] so the docs keep their own vertical rhythm
/// and every call site stays a one-argument constructor.
class DocCode extends StatelessWidget {
  const DocCode(this.code, {super.key, this.language = 'dart', this.filename});

  final String code;
  final String language;

  /// Optional header file name, which also moves the copy button into a header.
  final String? filename;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 24),
    child: CodeBlock(code: code, language: language, filename: filename),
  );
}

/// Parses a deliberately small inline syntax: backticks become mono and double
/// asterisks become semibold. Full Markdown would be another dependency and the
/// docs are authored as widgets, so nothing more is needed.
List<InlineSpan> inlineSpans(String text, AppColors colors) {
  final pattern = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`');
  final spans = <InlineSpan>[];
  var last = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > last) {
      spans.add(TextSpan(text: text.substring(last, match.start)));
    }
    final bold = match.group(1);
    if (bold != null) {
      spans.add(
        TextSpan(
          text: bold,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: match.group(2),
          style: TextStyle(
            color: colors.foreground,
            fontFamily: AppFonts.mono,
            fontSize: 14,
          ),
        ),
      );
    }
    last = match.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last)));
  }
  return spans;
}
