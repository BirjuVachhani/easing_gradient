// Regenerates the figures embedded in README.md.
//
// Run from the package root:
//
//     flutter test tool/generate_readme_images.dart
//
// Then optimize losslessly for web delivery:
//
//     python3 tool/optimize_readme_images.py
//
// The optimizer keeps the dithered hero scrims as PNG and converts the other
// figures to exact lossless WebP after checking decoded RGBA hashes.
//
// Output goes to doc/images/. The edge-fade figures load the tracked Roboto font
// from tool/fonts/, because flutter_test's default Ahem font turns prose into
// blocks. Its source and Apache 2.0 license are documented beside the font.
//
// Every figure is drawn straight onto a recorded canvas instead of through a
// widget tree. The gradients under test are the same objects a caller would
// build, so what lands in the PNG is the real shader output.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rasterization factor for every figure.
///
/// Figures are laid out in logical pixels and written at twice that size, so
/// README renderers that scale them down to a table column still show a crisp
/// image on high-density displays.
const double _scale = 2;

/// Corner radius shared by every figure, matching the example app's cards.
const double _radius = 12;

/// Preview size for the color-space and step-position table columns.
const Size _stripSize = Size(200, 40);

/// Preview size for figures compared two at a time in their own table row.
const Size _wideStripSize = Size(320, 56);

/// A 16:9 canvas large enough for a scrim seam to be visible after scaling.
const Size _sceneSize = Size(480, 270);

/// Where the text scrim starts, as a fraction of [_sceneSize] height.
///
/// A short scrim is the unflattering case: the shorter the ramp, the steeper a
/// linear alpha slope has to be, and the more obvious the corner where it
/// starts. That corner is the seam this package exists to remove.
const double _scrimTop = 0.42;

/// A canvas standing in for a small scrolling list viewport.
///
/// Wider than the list it depicts, because the artifact that separates a linear
/// mask from an eased one is a horizontal band. Horizontal extent is what lets
/// the eye see it.
const Size _columnSize = Size(320, 300);

/// Viewport backgrounds for the edge-fade comparisons.
const Color _blackSurface = Color(0xFF000000);
const Color _whiteSurface = Color(0xFFFFFFFF);

/// Endpoints for the color-space comparison.
///
/// Blue to yellow crosses most of the hue circle, which is what separates a
/// straight-line space such as OKLab from a hue-sweeping space such as OKLCH.
const Color _spaceFrom = Color(0xFF2563EB);
const Color _spaceTo = Color(0xFFFACC15);

/// Row accent colors for the edge-fade figures.
const List<Color> _accents = <Color>[
  Color(0xFF6D5EF7),
  Color(0xFF22D3EE),
  Color(0xFFF472B6),
  Color(0xFFFACC15),
  Color(0xFF34D399),
  Color(0xFFF97316),
];

/// Each edge is a separate two-color alpha mask.
const List<Color> _leadingMaskColors = <Color>[
  Colors.transparent,
  Colors.black,
];
const List<Color> _trailingMaskColors = <Color>[
  Colors.black,
  Colors.transparent,
];

/// Each fade spans nearly a third of the viewport, giving the alpha ramp enough
/// distance to resolve smoothly through multiple paragraph baselines.
const double _maskExtent = 0.30;

/// Font family registered only for the generated documentation figures.
const String _figureFontFamily = 'README Roboto';

/// List-tile content repeated in both edge-fade figures.
const List<({String title, String body})> _feedItems = [
  (
    title: 'Morning notes',
    body: 'Review the release checklist and update the documentation examples.',
  ),
  (
    title: 'Design review',
    body: 'Compare the pacing of the fade across several lines of real text.',
  ),
  (
    title: 'Reading list',
    body: 'Smooth transitions keep the content legible without a visible seam.',
  ),
];

const String _leadingParagraph =
    'A softer reading edge lets paragraphs dissolve naturally as they move '
    'beneath the top of the viewport.';
const String _trailingParagraph =
    'Long-form text stays readable until it approaches the bottom edge, then '
    'disappears without a visible dividing line.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes every README figure', () async {
    await _loadFigureFont();
    final Directory directory = Directory('doc/images');
    directory.createSync(recursive: true);
    for (final file in directory.listSync().whereType<File>()) {
      if (file.path.endsWith('.png') || file.path.endsWith('.webp')) {
        file.deleteSync();
      }
    }

    // Quick start: the seam a linear scrim leaves where it begins.
    await _writeScene(
      'scrim-native.png',
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Colors.transparent, Colors.black],
      ),
    );
    await _writeScene(
      'scrim-eased.png',
      EasingLinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const <Color>[Colors.transparent, Colors.black],
      ),
    );

    // Color spaces: identical endpoints and pacing, so only the path differs.
    for (final EasingColorSpace space in EasingColorSpace.values) {
      await _writeStrip(
        'space-${_fileSafe(space.name)}.png',
        _stripSize,
        EasingLinearGradient(
          colors: const <Color>[_spaceFrom, _spaceTo],
          curve: Curves.linear,
          colorSpace: space,
        ),
      );
    }

    // Hard bands: one figure per CSS step position.
    for (final StepPosition position in StepPosition.values) {
      await _writeStrip(
        'steps-${_fileSafe(position.name)}.png',
        _stripSize,
        EasingLinearGradient(
          colors: const <Color>[Color(0xFF111827), Color(0xFFF97316)],
          curve: StepsCurve(5, position: position),
        ),
      );
    }

    // Per-transition curves: same palette, different pacing per segment.
    const List<Color> palette = <Color>[
      Color(0xFF0F172A),
      Color(0xFF38BDF8),
      Color(0xFFFDE047),
      Color(0xFFEF4444),
    ];
    await _writeStrip(
      'transitions-global.png',
      _wideStripSize,
      EasingLinearGradient(colors: palette),
    );
    await _writeStrip(
      'transitions-per-segment.png',
      _wideStripSize,
      EasingLinearGradient(
        colors: palette,
        transitionCurves: const <Curve?>[
          Curves.easeOutCubic,
          null,
          Curves.easeInCubic,
        ],
      ),
    );

    // Sample density: a sharp curve is where the approximation shows.
    const List<Color> quint = <Color>[Color(0xFF1E1B4B), Color(0xFFFDE047)];
    await _writeStrip(
      'density-coarse.png',
      _wideStripSize,
      EasingLinearGradient(
        colors: quint,
        curve: Curves.easeInOutQuint,
        samplesPerTransition: 3,
      ),
    );
    await _writeStrip(
      'density-default.png',
      _wideStripSize,
      EasingLinearGradient(colors: quint, curve: Curves.easeInOutQuint),
    );

    // Edge fade: identical two-color masks on dark and light viewports.
    await _writeEdgeFade(
      'edge-fade-black-linear.png',
      eased: false,
      surface: _blackSurface,
      primaryText: const Color(0xFFF5F7FC),
      secondaryText: const Color(0xFFB8C0CF),
    );
    await _writeEdgeFade(
      'edge-fade-black-eased.png',
      eased: true,
      surface: _blackSurface,
      primaryText: const Color(0xFFF5F7FC),
      secondaryText: const Color(0xFFB8C0CF),
    );
    await _writeEdgeFade(
      'edge-fade-white-linear.png',
      eased: false,
      surface: _whiteSurface,
      primaryText: const Color(0xFF171A21),
      secondaryText: const Color(0xFF555E6E),
    );
    await _writeEdgeFade(
      'edge-fade-white-eased.png',
      eased: true,
      surface: _whiteSurface,
      primaryText: const Color(0xFF171A21),
      secondaryText: const Color(0xFF555E6E),
    );

    final List<FileSystemEntity> written = directory.listSync()
      ..sort(
        (FileSystemEntity a, FileSystemEntity b) => a.path.compareTo(b.path),
      );
    stdout.writeln('Wrote ${written.length} figures to ${directory.path}/');
  });
}

/// Loads the repository-owned Roboto Regular used by documentation figures.
Future<void> _loadFigureFont() async {
  final font = File('tool/fonts/Roboto-Regular.ttf');
  if (!font.existsSync()) {
    throw StateError(
      'README figures need tool/fonts/Roboto-Regular.ttf. Run the generator '
      'from the package root and restore the tracked font if it is missing.',
    );
  }
  final data = font.readAsBytesSync();
  await (FontLoader(
    _figureFontFamily,
  )..addFont(Future<ByteData>.value(ByteData.sublistView(data)))).load();
}

/// Records [paint] at [size] logical pixels and writes it as a PNG.
Future<void> _write(
  String name,
  Size size,
  void Function(Canvas canvas, Size size) paint,
) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.scale(_scale);
  paint(canvas, size);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(
    (size.width * _scale).round(),
    (size.height * _scale).round(),
  );
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  if (data == null) {
    throw StateError('Encoding $name produced no bytes.');
  }
  File('doc/images/$name').writeAsBytesSync(data.buffer.asUint8List());
}

/// Fills the whole rounded figure with [gradient].
Future<void> _writeStrip(String name, Size size, Gradient gradient) {
  return _write(name, size, (Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(_radius)),
      Paint()..shader = gradient.createShader(rect),
    );
  });
}

/// Draws a colorful backdrop, lays [scrim] over its lower two thirds, then puts
/// caption bars on top so the overlay is read as a text scrim.
Future<void> _writeScene(String name, Gradient scrim) {
  return _write(name, _sceneSize, (Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(_radius)),
    );
    // The backdrop runs left to right so that every horizontal edge in the
    // finished figure belongs to the scrim rather than to the scene behind it.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Color(0xFFFFB36B),
            Color(0xFFE0629B),
            Color(0xFF6D5EF7),
            Color(0xFF2DD4BF),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.6, -0.9),
          radius: 1.2,
          colors: <Color>[Color(0x66FFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect),
    );

    final Rect scrimRect = Rect.fromLTRB(
      0,
      size.height * _scrimTop,
      size.width,
      size.height,
    );
    canvas.drawRect(scrimRect, Paint()..shader = scrim.createShader(scrimRect));

    _bar(
      canvas,
      Rect.fromLTWH(26, size.height - 66, size.width * 0.56, 12),
      Colors.white,
      0.95,
    );
    _bar(
      canvas,
      Rect.fromLTWH(26, size.height - 46, size.width * 0.40, 8),
      Colors.white,
      0.6,
    );
    _bar(
      canvas,
      Rect.fromLTWH(26, size.height - 30, size.width * 0.26, 8),
      Colors.white,
      0.4,
    );
  });
}

/// Draws a scrolling-list stand-in, then applies one two-color mask per edge.
Future<void> _writeEdgeFade(
  String name, {
  required bool eased,
  required Color surface,
  required Color primaryText,
  required Color secondaryText,
}) {
  Gradient createMask(List<Color> colors) => eased
      ? EasingLinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        )
      : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        );

  final Gradient leadingMask = createMask(_leadingMaskColors);
  final Gradient trailingMask = createMask(_trailingMaskColors);

  return _write(name, _columnSize, (Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Rect leadingRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height * _maskExtent,
    );
    final Rect trailingRect = Rect.fromLTWH(
      0,
      size.height * (1 - _maskExtent),
      size.width,
      size.height * _maskExtent,
    );
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(_radius)),
    );
    canvas.drawRect(rect, Paint()..color = surface);

    canvas.saveLayer(rect, Paint());
    _paintRows(
      canvas,
      size,
      primaryText: primaryText,
      secondaryText: secondaryText,
    );
    canvas.drawRect(
      leadingRect,
      Paint()
        ..shader = leadingMask.createShader(leadingRect)
        ..blendMode = BlendMode.dstIn,
    );
    canvas.drawRect(
      trailingRect,
      Paint()
        ..shader = trailingMask.createShader(trailingRect)
        ..blendMode = BlendMode.dstIn,
    );
    canvas.restore();
  });
}

/// Fills [size] with paragraphs at the edges and text list tiles between them.
///
/// Both masks cut through wrapped letterforms and baselines. Light content on a
/// dark surface makes the masks' modest alpha difference readable without
/// altering either side's text or layout.
void _paintRows(
  Canvas canvas,
  Size size, {
  required Color primaryText,
  required Color secondaryText,
}) {
  const double inset = 12;
  const double paragraphHeight = 64;
  const double tileHeight = 58;

  final Rect leading = Rect.fromLTWH(
    inset,
    -18,
    size.width - inset * 2,
    paragraphHeight,
  );
  _paintText(
    canvas,
    _leadingParagraph,
    Offset(leading.left + 12, leading.top + 11),
    width: leading.width - 24,
    fontSize: 10.5,
    height: 1.3,
    color: primaryText,
    maxLines: 3,
  );

  double top = 54;
  for (var index = 0; index < _feedItems.length; index++) {
    final item = _feedItems[index];
    final Rect row = Rect.fromLTWH(
      inset,
      top,
      size.width - inset * 2,
      tileHeight,
    );
    canvas.drawCircle(
      Offset(row.left + 21, row.center.dy),
      9,
      Paint()..color = _accents[index % _accents.length],
    );
    final double textLeft = row.left + 40;
    final double textWidth = row.right - textLeft - 12;
    _paintText(
      canvas,
      item.title,
      Offset(textLeft, row.top + 7),
      width: textWidth,
      fontSize: 11,
      height: 1.15,
      color: primaryText,
      weight: FontWeight.w600,
      maxLines: 1,
    );
    _paintText(
      canvas,
      item.body,
      Offset(textLeft, row.top + 23),
      width: textWidth,
      fontSize: 9,
      height: 1.22,
      color: secondaryText,
      maxLines: 2,
    );
    top += tileHeight + 6;
  }

  final Rect trailing = Rect.fromLTWH(
    inset,
    246,
    size.width - inset * 2,
    paragraphHeight,
  );
  _paintText(
    canvas,
    _trailingParagraph,
    Offset(trailing.left + 12, trailing.top + 10),
    width: trailing.width - 24,
    fontSize: 10.5,
    height: 1.3,
    color: primaryText,
    maxLines: 3,
  );
}

/// Paints a constrained paragraph using the font loaded by [_loadFigureFont].
void _paintText(
  Canvas canvas,
  String text,
  Offset offset, {
  required double width,
  required double fontSize,
  required double height,
  required Color color,
  FontWeight weight = FontWeight.w400,
  required int maxLines,
}) {
  final builder =
      ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontFamily: _figureFontFamily,
          fontSize: fontSize,
          height: height,
          maxLines: maxLines,
          ellipsis: '…',
        ),
      )..pushStyle(
        ui.TextStyle(
          color: color,
          fontFamily: _figureFontFamily,
          fontSize: fontSize,
          fontWeight: weight,
          height: height,
        ),
      );
  final paragraph = (builder..addText(text)).build();
  paragraph.layout(ui.ParagraphConstraints(width: width));
  canvas.drawParagraph(paragraph, offset);
  paragraph.dispose();
}

/// Draws one pill-shaped stand-in for a line of text.
void _bar(Canvas canvas, Rect rect, Color color, double opacity) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
    Paint()..color = color.withValues(alpha: opacity),
  );
}

/// Converts a camelCase enum name into a kebab-case file name fragment.
String _fileSafe(String name) => name
    .replaceAllMapped(
      RegExp('[A-Z]'),
      (Match match) => '-${match[0]!.toLowerCase()}',
    )
    .toLowerCase();
