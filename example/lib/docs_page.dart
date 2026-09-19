import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'src/docs/docs_content.dart';
import 'src/docs/docs_sections.dart';
import 'src/theme/tokens.dart';
import 'src/widgets/app_shell.dart';
import 'src/widgets/section.dart';

const double _compactBarHeight = 52;

/// Package documentation with a sticky section rail beside one scrolling
/// reading column. On compact widths the rail becomes a contents sheet.
class DocsPage extends StatefulWidget {
  const DocsPage({super.key});

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  final ScrollController _controller = ScrollController();
  final List<GlobalKey> _keys = List.generate(
    docsSections.length,
    (_) => GlobalKey(),
  );
  int _active = 0;

  static const double _anchorGap = AppLayout.navHeight + 24;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final threshold = context.isCompact
        ? AppLayout.navHeight + _compactBarHeight + 24
        : AppLayout.navHeight + 72;
    var active = 0;
    for (var i = 0; i < _keys.length; i++) {
      final sectionContext = _keys[i].currentContext;
      if (sectionContext == null) continue;
      final box = sectionContext.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero).dy <= threshold) {
        active = i;
      } else {
        break;
      }
    }
    if (active != _active) setState(() => _active = active);
  }

  void _scrollTo(int index) {
    final sectionContext = _keys[index].currentContext;
    if (sectionContext == null || !_controller.hasClients) return;
    final box = sectionContext.findRenderObject() as RenderBox;
    final dy = box.localToGlobal(Offset.zero).dy;
    final gap = context.isCompact
        ? AppLayout.navHeight + _compactBarHeight + 16
        : _anchorGap;
    final target = (_controller.offset + dy - gap).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    setState(() => _active = index);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) =>
      context.isCompact ? _buildCompact(context) : _buildWide(context);

  Widget _buildWide(BuildContext context) {
    final railMaxHeight = math.max(
      0.0,
      MediaQuery.sizeOf(context).height - AppLayout.navHeight - 24,
    );
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SelectionArea(
        child: SingleChildScrollView(
          controller: _controller,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppLayout.navHeight + 24),
                child: ContentContainer(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StickyBox(
                        controller: _controller,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: railMaxHeight),
                          child: _Sidebar(active: _active, onTap: _scrollTo),
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(child: _sectionsColumn(context)),
                    ],
                  ),
                ),
              ),
              const SiteFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppLayout.navHeight),
        _CompactDocsBar(
          sectionTitle: docsSections[_active].title,
          onOpen: _openContents,
        ),
        Expanded(
          child: SelectionArea(
            child: SingleChildScrollView(
              controller: _controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_sectionsColumn(context), const SiteFooter()],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionsColumn(BuildContext context) {
    final compact = context.isCompact;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 0,
        compact ? 8 : 0,
        compact ? 20 : 0,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < docsSections.length; i++)
            Padding(
              key: _keys[i],
              padding: EdgeInsets.only(top: i == 0 ? 0 : 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(docsSections[i].title),
                  const SizedBox(height: 16),
                  ..._content(docsSections[i].id),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openContents() {
    final colors = context.colors;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        side: BorderSide(color: colors.border),
      ),
      builder: (sheetContext) {
        var index = 0;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in docsGroups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
                    child: Text(
                      group.title.toUpperCase(),
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  for (final section in group.sections)
                    Builder(
                      builder: (_) {
                        final sectionIndex = index++;
                        return ListTile(
                          dense: true,
                          title: Text(section.title),
                          trailing: sectionIndex == _active
                              ? const Icon(Icons.check_rounded, size: 17)
                              : null,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _scrollTo(sectionIndex);
                            });
                          },
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: context.colors.foreground,
      fontSize: 30,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.75,
      height: 1.2,
    ),
  );
}

class _Sidebar extends StatefulWidget {
  const _Sidebar({required this.active, required this.onTap});

  final int active;
  final ValueChanged<int> onTap;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  final ScrollController _controller = ScrollController();
  final List<GlobalKey> _tileKeys = List.generate(
    docsSections.length,
    (_) => GlobalKey(),
  );

  @override
  void didUpdateWidget(_Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealActive());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _revealActive() {
    if (!_controller.hasClients) return;
    final object = _tileKeys[widget.active].currentContext?.findRenderObject();
    if (object == null) return;
    for (final policy in const [
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    ]) {
      _controller.position.ensureVisible(
        object,
        alignmentPolicy: policy,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var index = 0;
    for (var groupIndex = 0; groupIndex < docsGroups.length; groupIndex++) {
      children.add(
        Padding(
          padding: EdgeInsets.only(
            top: groupIndex == 0 ? 0 : 22,
            bottom: 8,
            left: 10,
          ),
          child: Text(
            docsGroups[groupIndex].title.toUpperCase(),
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.65,
            ),
          ),
        ),
      );
      for (final section in docsGroups[groupIndex].sections) {
        final sectionIndex = index++;
        children.add(
          _SidebarTile(
            key: _tileKeys[sectionIndex],
            label: section.title,
            active: sectionIndex == widget.active,
            onTap: () => widget.onTap(sectionIndex),
          ),
        );
      }
    }
    return SizedBox(
      width: 220,
      child: SingleChildScrollView(
        controller: _controller,
        padding: const EdgeInsets.only(right: 12, bottom: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.active || _hovered
                ? colors.surfaceInset
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.active ? colors.foreground : colors.mutedForeground,
              fontSize: 13.5,
              fontWeight: widget.active ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyBox extends StatelessWidget {
  const _StickyBox({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, sticky) {
      final offset = controller.positions.length == 1 ? controller.offset : 0.0;
      return Transform.translate(offset: Offset(0, offset), child: sticky);
    },
    child: child,
  );
}

class _CompactDocsBar extends StatelessWidget {
  const _CompactDocsBar({required this.sectionTitle, required this.onOpen});

  final String sectionTitle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: Container(
            height: _compactBarHeight,
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: ContentContainer(
              child: Row(
                children: [
                  Text(
                    'Docs',
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.menu_rounded, size: 18, color: colors.foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _content(String id) => switch (id) {
  'introduction' => const [
    DocProse(
      '`easing_gradient` replaces straight color pacing with any Flutter '
      '`Curve`. It samples the eased color path once, then passes ordinary '
      'colors and stops to Flutter’s native linear, radial, or sweep shader.',
    ),
    DocProse(
      'The default curve is `Curves.easeInOut`; the default interpolation space '
      'is **OKLab**. The package has no runtime dependencies and works anywhere '
      'Flutter’s painting APIs work.',
    ),
    DocNote(
      'Easing changes pacing, not output bit depth. Visible banding can also '
      'come from renderer quantization, alpha compositing, display profiles, '
      'or the physical panel.',
    ),
  ],
  'installation' => const [
    DocProse('Add the package from the command line:'),
    DocCode('flutter pub add easing_gradient', language: 'shell'),
    DocProse('Or declare the dependency in `pubspec.yaml`:'),
    DocCode('''dependencies:
  easing_gradient: ^0.2.0''', language: 'yaml'),
    DocProse(
      'Version 0.2.0 requires Flutter 3.47.1 or newer, including Dart 3.13.1.',
    ),
  ],
  'quick-start' => const [
    DocProse('Replace `LinearGradient` with `EasingLinearGradient`:'),
    DocCode('''Container(
  decoration: BoxDecoration(
    gradient: EasingLinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Colors.transparent, Colors.black],
    ),
  ),
)'''),
    DocProse(
      'Radial and sweep gradients expose the same easing and color controls '
      'alongside their normal Flutter geometry.',
    ),
  ],
  'gradients' => const [
    DocTable(
      headers: ['Class', 'Flutter parent', 'Geometry'],
      rows: [
        [
          '`EasingLinearGradient`',
          '`LinearGradient`',
          'begin, end, tile mode, transform',
        ],
        [
          '`EasingRadialGradient`',
          '`RadialGradient`',
          'center, radius, focal, focal radius',
        ],
        [
          '`EasingSweepGradient`',
          '`SweepGradient`',
          'center, start angle, end angle',
        ],
      ],
    ),
    DocProse(
      'Each factory stores compact input in `sourceColors` and `sourceStops`. '
      'The inherited `colors` and `stops` fields contain shader-ready sampled data.',
    ),
  ],
  'sampler' => const [
    DocProse(
      'Use `easeColorStops` when another API accepts colors and stops, such as '
      'a custom painter or `dart:ui.Gradient`.',
    ),
    DocCode('''final (:colors, :stops) = easeColorStops(
  colors: const [Colors.black, Colors.transparent],
  curve: Curves.easeOutCubic,
  samplesPerTransition: 15,
);'''),
    DocBullets([
      'Returned lists are unmodifiable.',
      'Two opaque colors at the default produce 17 entries: 15 interior points plus endpoints.',
      'A transparent endpoint can add a zero-width limiting-color stop.',
      'Sampling is synchronous. Retain stable gradients instead of rebuilding them every frame.',
    ]),
  ],
  'transitions' => const [
    DocProse(
      'A multi-color gradient can use a different curve per neighboring pair. '
      'A null entry falls back to the global curve.',
    ),
    DocCode('''EasingLinearGradient(
  colors: const [Colors.red, Colors.yellow, Colors.blue],
  curve: Curves.easeInOut,
  transitionCurves: const [Curves.easeOut, null],
)'''),
    DocNote(
      '`transitionCurves` must contain exactly `colors.length - 1` entries.',
    ),
  ],
  'steps' => const [
    DocProse(
      '`StepsCurve` implements CSS-style `steps()` easing. The sampler emits '
      'duplicated stop positions, so boundaries are exact hard edges rather '
      'than tiny ramps.',
    ),
    DocCode('''EasingLinearGradient(
  colors: const [Colors.black, Colors.white],
  curve: const StepsCurve(
    5,
    position: StepPosition.jumpNone,
  ),
)'''),
    DocBullets([
      '`jumpStart`: the first visible band is already raised.',
      '`jumpEnd`: preserves the start-color band; the default.',
      '`jumpBoth`: skips both endpoint bands.',
      '`jumpNone`: shows both endpoints as full bands and needs at least two steps.',
    ]),
  ],
  'color-spaces' => const [
    DocProse('`colorSpace` selects the mathematical path between endpoints.'),
    DocTable(
      headers: ['Value', 'Use it for'],
      rows: [
        ['`oklab`', 'Perceptually even everyday fades; package default'],
        ['`oklch`', 'Short-path hue sweeps and saturated effects'],
        ['`linearRgb`', 'Physically correct light mixing'],
        ['`srgb`', 'Native RGB-coordinate parity'],
        ['`hsl`', 'Familiar CSS-style hue interpolation'],
      ],
    ),
    DocProse(
      'Non-hue components are alpha-weighted before interpolation. OKLCH and '
      'HSL interpolate hue separately along the shorter arc.',
    ),
  ],
  'wide-gamut' => const [
    DocProse(
      '`outputColorSpace` is separate from `colorSpace`. Output defaults to '
      'sRGB for compatibility; opt into Display P3 or extended sRGB explicitly.',
    ),
    DocCode('''EasingLinearGradient(
  colors: p3Colors,
  colorSpace: EasingColorSpace.oklab,
  outputColorSpace: ColorSpace.displayP3,
)'''),
    DocNote(
      'A wide-gamut Color does not guarantee wide-gamut physical output. '
      'Flutter backend adapters, the render target, OS color management, and '
      'the display must all preserve it.',
    ),
  ],
  'transparency' => const [
    DocProse(
      'Rectangular color spaces premultiply components by alpha during mixing. '
      'White fading to transparent black therefore remains white while alpha '
      'falls instead of becoming a gray fringe.',
    ),
    DocProse(
      'Flutter’s native gradients interpolate supplied stops in straight RGBA '
      'and premultiply afterward. The sampler adds a zero-width limiting-RGB '
      'guard before a fully transparent endpoint to prevent hidden RGB leaking '
      'through the final interval.',
    ),
  ],
  'accuracy' => const [
    DocProse(
      'The stable renderer is a piecewise-linear approximation of a continuous '
      'curve and color path. Fifteen interior samples are the default. Sharper '
      'curves and gamut clipping can need more.',
    ),
    DocBullets([
      'Use 31 or 63 samples for quintic, elastic, or back curves when model error is visible.',
      'More stops improve approximation but cannot restore precision lost later in the renderer or display path.',
      'The Accuracy Lab compares uniform, dense uniform, Bézier-parameter, and bounded adaptive placement.',
      'Its reference is a CPU model, not framebuffer or monitor measurement.',
    ]),
  ],
  'performance' => const [
    DocProse(
      'Color conversion and curve sampling happen during construction. A '
      'retained instance paints through the same native shader path as a '
      'hand-written gradient carrying the same stops.',
    ),
    DocProse(
      'The included profile benchmark compares compact native, stop-matched '
      'dense native, and easing-wrapper variants across linear, radial, and '
      'sweep geometry. Re-run it on the target device after changing stop count '
      'or rendering behavior.',
    ),
    DocCode('''cd example
flutter drive --profile \\
  -d <physical-device-id> \\
  --target integration_test/gradient_performance_test.dart \\
  --driver test_driver/performance_driver.dart''', language: 'shell'),
  ],
  'animation' => const [
    DocProse(
      'Inherited `scale`, `withOpacity`, and Flutter gradient interpolation '
      'return the base gradient type. They preserve generated stops but discard '
      'package-specific source metadata.',
    ),
    DocNote(
      'Flutter 3.47.4 Color.lerp rejects extended-sRGB colors in debug mode. '
      'Rebuild an extended-output gradient from source configuration instead '
      'of relying on inherited interpolation.',
    ),
  ],
  'limitations' => const [
    DocBullets([
      'Sampling cannot guarantee zero error for every arbitrary Curve; a narrow spike can fall between finite probes.',
      'Bounded sRGB and P3 output use channel clipping, not perceptual gamut mapping.',
      'HSL interpolation uses bounded sRGB working coordinates even when output is wide gamut.',
      'Hard StepsCurve boundaries can soften midway through Flutter gradient interpolation because duplicate positions are merged.',
      'Native rendering does not guarantee dithering or band-free physical output on every backend and display.',
    ]),
  ],
  _ => const [],
};
