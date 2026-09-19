import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';

import 'alpha_fade.dart';
import 'src/theme/tokens.dart';
import 'src/widgets/app_shell.dart';
import 'src/widgets/code_block.dart';
import 'src/widgets/controls.dart';
import 'src/widgets/section.dart';
import 'src/widgets/iphone_frame.dart';

/// Fades the leading and trailing edges of a widget instead of cutting them off.
///
/// The gradient is used as an alpha mask rather than as paint: [BlendMode.dstIn]
/// keeps the child's own colors and multiplies its alpha by the mask's alpha, so
/// only the mask's alpha channel matters. Content dissolves into whatever is
/// painted behind it, which is what separates this from stacking an opaque scrim
/// on top and hoping it matches the background.
///
/// Easing is what makes the effect disappear. A linear alpha ramp changes slope
/// abruptly where it meets the opaque middle, and that corner reads as a faint
/// crease across the content.
///
/// Both masks are built in [build], and only their shaders are created in the
/// paint callbacks. `ShaderMask` invokes `shaderCallback` on every paint, so
/// sampling a curve inside one would redo the work on every frame of a scroll.
class EdgeFade extends StatelessWidget {
  const EdgeFade({
    super.key,
    required this.child,
    this.extent = 0.30,
    this.leadingLength,
    this.trailingLength,
    this.curve = Curves.easeInOut,
    this.direction = Axis.vertical,
    this.eased = true,
    this.samples = 15,
  });

  /// The widget whose edges are faded, usually a scrollable.
  final Widget child;

  /// Fraction of the long axis each fade covers, clamped to at most a half.
  ///
  /// Ignored for an edge that supplies [leadingLength] or [trailingLength].
  final double extent;

  /// Length of the leading fade in logical pixels, overriding [extent].
  ///
  /// A fade that has to line up with system chrome, such as a status bar or a
  /// home indicator, is a fixed distance rather than a share of the viewport.
  final double? leadingLength;

  /// Length of the trailing fade in logical pixels, overriding [extent].
  final double? trailingLength;

  /// Shape of the alpha ramp. Ignored when [eased] is false.
  final Curve curve;

  /// Which pair of edges fades: top and bottom, or left and right.
  final Axis direction;

  /// Whether to build the mask with [EasingLinearGradient] or a plain
  /// [LinearGradient]. Present so the demo can show the two side by side.
  final bool eased;

  /// Interior samples per transition for the native eased mask.
  final int samples;

  @override
  Widget build(BuildContext context) {
    final bool vertical = direction == Axis.vertical;
    final AlignmentGeometry begin = vertical
        ? Alignment.topCenter
        : Alignment.centerLeft;
    final AlignmentGeometry end = vertical
        ? Alignment.bottomCenter
        : Alignment.centerRight;

    // Each edge is a literal two-color gradient. Only alpha survives
    // BlendMode.dstIn, so the opaque color itself is arbitrary.
    const List<Color> leadingColors = <Color>[Colors.transparent, Colors.black];
    const List<Color> trailingColors = <Color>[
      Colors.black,
      Colors.transparent,
    ];
    if (extent <= 0 && leadingLength == null && trailingLength == null) {
      return child;
    }

    // A pixel length only becomes a fraction once the paint bounds are known,
    // so both edges resolve inside the bounds callbacks below.
    double edge(double? length, double span) =>
        (length != null ? length / span : extent).clamp(0.0, 0.5);

    Gradient createMask(List<Color> colors) => eased
        ? EasingLinearGradient(
            begin: begin,
            end: end,
            colors: colors,
            curve: curve,
            samplesPerTransition: samples,
          )
        : LinearGradient(begin: begin, end: end, colors: colors);

    final Gradient leadingMask = createMask(leadingColors);
    final Gradient trailingMask = createMask(trailingColors);

    Rect leadingBounds(Rect bounds) {
      final double span = vertical ? bounds.height : bounds.width;
      final double length = span * edge(leadingLength, span);
      return vertical
          ? Rect.fromLTWH(bounds.left, bounds.top, bounds.width, length)
          : Rect.fromLTWH(bounds.left, bounds.top, length, bounds.height);
    }

    Rect trailingBounds(Rect bounds) {
      final double span = vertical ? bounds.height : bounds.width;
      final double length = span * edge(trailingLength, span);
      return vertical
          ? Rect.fromLTWH(
              bounds.left,
              bounds.bottom - length,
              bounds.width,
              length,
            )
          : Rect.fromLTWH(
              bounds.right - length,
              bounds.top,
              length,
              bounds.height,
            );
    }

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) =>
          leadingMask.createShader(leadingBounds(bounds)),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) =>
            trailingMask.createShader(trailingBounds(bounds)),
        child: child,
      ),
    );
  }
}

/// Named curve option for the edge-fade controls.
class _FadeCurve {
  const _FadeCurve(this.name, this.curve);
  final String name;
  final Curve curve;
}

const List<_FadeCurve> _fadeCurves = <_FadeCurve>[
  _FadeCurve('Ease in/out', Curves.easeInOut),
  _FadeCurve('Ease out cubic', Curves.easeOutCubic),
  _FadeCurve('Ease in/out cubic', Curves.easeInOutCubic),
  _FadeCurve('Ease in/out quint', Curves.easeInOutQuint),
];

/// Recipe page for masking a scrollable's edges with an eased gradient.
///
/// The preview keeps a live scrollable inside the mask on purpose. A static
/// column would hide the property that matters in production: the mask belongs
/// to the viewport, so content dissolves as it passes under the edge.
class EdgeFadePage extends StatefulWidget {
  const EdgeFadePage({super.key});

  @override
  State<EdgeFadePage> createState() => _EdgeFadePageState();
}

class _EdgeFadePageState extends State<EdgeFadePage> {
  var _extent = 0.30;
  var _curve = _fadeCurves.first;
  var _enabled = true;
  var _compare = false;
  var _lightBackground = false;
  var _diagnostics = false;

  // Paragraphs first: long prose passing under the fade shows the ramp better
  // than list rows, which break the edge up into separate blocks.
  var _content = 1;
  var _samples = 15;
  var _dither = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = context.isCompact;

    Widget preview({required bool eased, required bool phoneList}) {
      final content = phoneList
          ? _PhoneList(
              curve: _curve.curve,
              enabled: _enabled,
              eased: eased,
              samples: _samples,
              lightBackground: _lightBackground,
            )
          : _PhoneParagraphs(
              curve: _curve.curve,
              enabled: _enabled,
              eased: eased,
              samples: _samples,
              lightBackground: _lightBackground,
            );
      return _FramedFadePreview(
        key: ValueKey(
          'edge-fade-preview-${eased ? 'eased' : 'linear'}-${phoneList ? 'list' : 'paragraphs'}',
        ),
        label: _enabled
            ? eased
                  ? 'Eased mask'
                  : 'Linear mask'
            : 'No mask',
        detail: _enabled
            ? eased
                  ? 'EasingLinearGradient · ${_curve.name}'
                  : 'LinearGradient · no easing'
            : 'Content is clipped at the viewport edge',
        lightBackground: _lightBackground,
        child: content,
      );
    }

    final phoneList = _content == 0;
    final previews = _PreviewLayout(
      primary: preview(eased: true, phoneList: phoneList),
      secondary: _compare ? preview(eased: false, phoneList: phoneList) : null,
    );

    final controls = ControlPanel(
      title: 'MASK',
      children: [
        SegmentedButton<int>(
          key: const ValueKey('edge-fade-content'),
          segments: const [
            ButtonSegment(value: 0, label: Text('List')),
            ButtonSegment(value: 1, label: Text('Paragraphs')),
          ],
          selected: {_content},
          showSelectedIcon: false,
          onSelectionChanged: (value) => setState(() => _content = value.first),
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.dark_mode_outlined, size: 15),
              label: Text('Black'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.light_mode_outlined, size: 15),
              label: Text('White'),
            ),
          ],
          selected: {_lightBackground},
          showSelectedIcon: false,
          onSelectionChanged: (value) =>
              setState(() => _lightBackground = value.first),
        ),
        const SizedBox(height: 14),
        LabeledSwitch(
          title: 'Fade edges',
          subtitle: 'Turn off to see the hard viewport edge',
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
        ),
        LabeledSwitch(
          title: 'Compare against a linear mask',
          subtitle:
              'A linear alpha ramp creases where it meets the opaque middle',
          value: _compare,
          onChanged: (value) => setState(() => _compare = value),
        ),
        const SizedBox(height: 14),
        // Both phone examples size their fades from the safe areas, so there is
        // no fractional extent to expose here. The analytic shader previews
        // below still use one, and show their own slider when enabled.
        Text(
          'Fade lengths follow the status bar and the home indicator.',
          style: TextStyle(
            color: context.colors.mutedForeground,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        LabeledDropdown<_FadeCurve>(
          label: 'Curve',
          value: _curve,
          values: _fadeCurves,
          display: (option) => option.name,
          onChanged: (option) => setState(() => _curve = option),
        ),
        const SizedBox(height: 18),
        LabeledSlider(
          key: const ValueKey('edge-fade-samples'),
          label: 'Native interior samples',
          value: _samples.toDouble(),
          min: 1,
          max: 255,
          divisions: 254,
          onChanged: (value) => setState(() => _samples = value.round()),
        ),
        const SizedBox(height: 10),
        LabeledSwitch(
          title: 'Show alpha-dithering experiment',
          subtitle: 'Example-only shader, not a verified banding fix',
          value: _diagnostics,
          onChanged: (value) => setState(() => _diagnostics = value),
        ),
        if (_diagnostics) ...[
          const SizedBox(height: 10),
          LabeledSlider(
            label: 'Analytic fade extent',
            value: _extent,
            max: 0.45,
            min: 0,
            divisions: 45,
            valueLabel: '${(_extent * 100).round()}%',
            onChanged: (value) => setState(() => _extent = value),
          ),
          const SizedBox(height: 10),
          LabeledSlider(
            key: const ValueKey('edge-fade-dither'),
            label: 'Peak-to-peak alpha noise',
            value: _dither,
            min: 0,
            max: 4,
            divisions: 16,
            valueLabel: '${_dither.toStringAsFixed(1)} / 255',
            onChanged: (value) => setState(() => _dither = value),
          ),
        ],
      ],
    );

    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Section(
              top: AppLayout.navHeight + (compact ? 40 : 64),
              bottom: 0,
              child: const PageHeading(
                title: 'Edge fade',
                subtitle:
                    'Mask a scrollable with a gradient so its top and bottom '
                    'edges dissolve into the background instead of being cut '
                    'off. Only the mask’s alpha survives dstIn, which makes '
                    'this the one recipe here where the color interpolation '
                    'work has nothing to contribute.',
              ),
            ),
            Section(
              top: 32,
              bottom: 0,
              child: DemoLayout(preview: previews, controls: controls),
            ),
            if (_diagnostics)
              Section(
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeading(
                      title: 'Alpha-dithering experiment',
                      subtitle:
                          'Both controls use identical analytic cubic easing '
                          'and one mask layer, so only the alpha noise differs. '
                          'RGB dithering cannot affect a dstIn mask. The native '
                          'masks above use two layers and Flutter\'s own cubic '
                          'solver, so compare the two shader previews with each '
                          'other rather than with the previews above.',
                    ),
                    const SizedBox(height: 24),
                    _PreviewLayout(
                      primary: _FadePreview(
                        label: 'Analytic mask, no noise',
                        detail: 'Per-pixel cubic; one mask layer',
                        extent: _extent,
                        curve: _curve.curve,
                        enabled: _enabled,
                        lightBackground: _lightBackground,
                        analyticDither: 0,
                      ),
                      secondary: _FadePreview(
                        label: 'Analytic mask, alpha noise',
                        detail:
                            'Stable screen-scale noise; alpha endpoints pinned',
                        extent: _extent,
                        curve: _curve.curve,
                        enabled: _enabled,
                        lightBackground: _lightBackground,
                        analyticDither: _dither,
                      ),
                    ),
                  ],
                ),
              ),
            Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    title: 'The recipe',
                    subtitle:
                        'Build the gradient in build and pass createShader as '
                        'the callback. ShaderMask asks for a shader on every '
                        'paint, so constructing the gradient inside the '
                        'callback would resample the curve on every frame of a '
                        'scroll.',
                  ),
                  const SizedBox(height: 20),
                  const CodeBlock(code: _snippet, filename: 'edge_fade.dart'),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.readingMaxWidth,
                    ),
                    child: Text(
                      'Swap begin and end for centerLeft and centerRight to '
                      'fade a horizontal list instead.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }
}

const String _snippet = '''
// One literal two-color gradient per edge.
final topFade = EasingLinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: const [Colors.transparent, Colors.black],
);
final bottomFade = EasingLinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: const [Colors.black, Colors.transparent],
);

return LayoutBuilder(
  builder: (context, constraints) {
    final h = constraints.maxHeight;
    final top = Rect.fromLTWH(0, 0, constraints.maxWidth, h * 0.30);
    final bottom = Rect.fromLTWH(
      0,
      h * 0.70,
      constraints.maxWidth,
      h * 0.30,
    );
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (_) => topFade.createShader(top),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (_) => bottomFade.createShader(bottom),
        child: ListView.builder(...),
      ),
    );
  },
);''';

/// Places one or two previews side by side, stacking them when narrow.
///
/// The 700 logical-pixel threshold matches the comparison gallery so both pages
/// switch to a stacked layout at the same width.
class _PreviewLayout extends StatelessWidget {
  const _PreviewLayout({required this.primary, this.secondary});

  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final Widget? second = secondary;
    if (second == null) return primary;
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 700
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: primary),
                const SizedBox(width: 18),
                Expanded(child: second),
              ],
            )
          : Column(children: [primary, const SizedBox(height: 18), second]),
    );
  }
}

/// A mobile content example inside the real iPhone 17 Pro preset frame.
class _FramedFadePreview extends StatelessWidget {
  const _FramedFadePreview({
    super.key,
    required this.label,
    required this.detail,
    required this.lightBackground,
    required this.child,
  });

  final String label;
  final String detail;
  final bool lightBackground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        IPhone17ProFrame(
          height: 650,
          brightness: lightBackground ? Brightness.light : Brightness.dark,
          child: child,
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.mutedForeground, fontSize: 12.5),
        ),
      ],
    );
  }
}

/// Extra fade beyond the status bar, so content dissolves before it reaches
/// the very top of the screen rather than exactly at it.
const double _topFadeLead = 56;

/// Fade beyond the home indicator, the small amount of breathing room SwiftUI
/// leaves under a scrollable's soft bottom edge.
const double _bottomFadeLead = 26;

/// The fade lengths for a phone screen, measured from its safe areas.
///
/// These are fixed distances set by the system chrome, not a share of the
/// viewport, which is why neither example uses a fractional extent.
({double top, double bottom}) _phoneFades(BuildContext context) {
  final EdgeInsets safeArea = MediaQuery.paddingOf(context);
  return (
    top: safeArea.top + _topFadeLead,
    bottom: safeArea.bottom + _bottomFadeLead,
  );
}

/// Phone example containing a scrollable list of compact, meaningful rows.
class _PhoneList extends StatelessWidget {
  const _PhoneList({
    required this.curve,
    required this.enabled,
    required this.eased,
    required this.samples,
    required this.lightBackground,
  });

  final Curve curve;
  final bool enabled;
  final bool eased;
  final int samples;
  final bool lightBackground;

  @override
  Widget build(BuildContext context) {
    final palette = _phonePalette(lightBackground);
    final fades = _phoneFades(context);
    final list = ListView.builder(
      padding: EdgeInsets.only(top: fades.top, bottom: fades.bottom),
      itemCount: 18,
      itemBuilder: (context, index) => _FadeRow(
        index: index,
        primaryText: palette.foreground,
        secondaryText: palette.muted,
      ),
    );
    return ColoredBox(
      color: palette.surface,
      child: enabled
          ? EdgeFade(
              leadingLength: fades.top,
              trailingLength: fades.bottom,
              curve: curve,
              eased: eased,
              samples: samples,
              child: list,
            )
          : list,
    );
  }
}

/// Phone example containing only long, scrollable prose paragraphs.
class _PhoneParagraphs extends StatelessWidget {
  const _PhoneParagraphs({
    required this.curve,
    required this.enabled,
    required this.eased,
    required this.samples,
    required this.lightBackground,
  });

  final Curve curve;
  final bool enabled;
  final bool eased;
  final int samples;
  final bool lightBackground;

  static const paragraphs = [
    'An edge fade is doing real work here. It lets text leave the viewport without a hard line cutting across the screen, which is the sort of thing you stop noticing once it is done well and cannot unsee when it is done badly.',
    'The top fade is as tall as the status bar plus a short lead, so prose is already gone by the time it reaches the very top of the screen. The bottom one is shorter still, covering the home indicator and a little breathing room above it.',
    'A linear ramp starts changing immediately and then stops at a corner. Easing flattens both ends of that ramp, so neither the beginning nor the point where it becomes fully opaque calls attention to itself.',
    'This demo intentionally uses only text. Letterforms contain thin strokes and broad counters, which makes uneven alpha pacing and visible bands easier to see than on a solid color block.',
    'Scroll slowly through the top and bottom edges. Toggle the linear comparison, switch between black and white, and raise the native sample count when inspecting a difficult display.',
    'The phone body is the iPhone 17 Pro preset from device_preview. It supplies the real screen shape, safe areas, Dynamic Island, and home indicator around this ordinary Flutter widget tree.',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _phonePalette(lightBackground);
    final fades = _phoneFades(context);

    final prose = ListView.separated(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: fades.top,
        bottom: fades.bottom,
      ),
      // The title scrolls with the prose rather than sitting in fixed chrome,
      // so it dissolves into the top fade like everything else. Large type is
      // the hardest thing for an alpha ramp to hide gracefully.
      itemCount: paragraphs.length * 2 + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'Soft edges',
            style: TextStyle(
              color: palette.foreground,
              fontFamily: 'Geist',
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.7,
            ),
          );
        }
        return Text(
          paragraphs[(index - 1) % paragraphs.length],
          style: TextStyle(
            color: palette.foreground,
            fontFamily: 'Geist',
            fontSize: 16,
            height: 1.65,
            letterSpacing: -0.1,
          ),
        );
      },
    );
    return ColoredBox(
      color: palette.surface,
      child: enabled
          ? EdgeFade(
              leadingLength: fades.top,
              trailingLength: fades.bottom,
              curve: curve,
              eased: eased,
              samples: samples,
              child: prose,
            )
          : prose,
    );
  }
}

typedef _PhonePalette = ({Color surface, Color foreground, Color muted});

_PhonePalette _phonePalette(bool light) => light
    ? (
        surface: Colors.white,
        foreground: const Color(0xFF171A21),
        muted: const Color(0xFF555E6E),
      )
    : (
        surface: Colors.black,
        foreground: const Color(0xFFF5F7FC),
        muted: const Color(0xFFB8C0CF),
      );

/// One masked scrollable plus its caption, used by the analytic shader controls.
class _FadePreview extends StatelessWidget {
  const _FadePreview({
    required this.label,
    required this.detail,
    required this.extent,
    required this.curve,
    required this.enabled,
    required this.lightBackground,
    required this.analyticDither,
  });

  final String label;
  final String detail;
  final double extent;
  final Curve curve;
  final bool enabled;
  final bool lightBackground;
  final double? analyticDither;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color surface = lightBackground ? Colors.white : Colors.black;
    final Color primaryText = lightBackground
        ? const Color(0xFF171A21)
        : const Color(0xFFF5F7FC);
    final Color secondaryText = lightBackground
        ? const Color(0xFF555E6E)
        : const Color(0xFFB8C0CF);
    final Widget list = ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 14,
      itemBuilder: (context, index) => _FadeRow(
        index: index,
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 320,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: enabled
                  ? AnalyticAlphaFade(
                      extent: extent,
                      curve: curve as Cubic,
                      dither: analyticDither ?? 0,
                      child: list,
                    )
                  : list,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Meaningful text tile with enough contrast for the fade to be visible.
class _FadeRow extends StatelessWidget {
  const _FadeRow({
    required this.index,
    required this.primaryText,
    required this.secondaryText,
  });

  static const List<({String title, String body})> _items = [
    (
      title: 'Morning notes',
      body: 'Review the checklist and update the documentation examples.',
    ),
    (
      title: 'Design review',
      body: 'Compare the fade across several lines of readable text.',
    ),
    (
      title: 'Reading list',
      body: 'Keep content legible without a visible dividing line.',
    ),
    (
      title: 'Project update',
      body: 'Long-form text disappears gently near the viewport edge.',
    ),
  ];

  static const List<Color> _accents = <Color>[
    Color(0xFF6D5EF7),
    Color(0xFF22D3EE),
    Color(0xFFF472B6),
    Color(0xFFFACC15),
    Color(0xFF34D399),
    Color(0xFFF97316),
  ];

  final int index;
  final Color primaryText;
  final Color secondaryText;

  @override
  Widget build(BuildContext context) {
    final item = _items[index % _items.length];
    return Container(
      // No fixed height: the bundled Geist metrics are taller than the stock
      // platform font this row was first laid out against.
      margin: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: _accents[index % _accents.length],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
