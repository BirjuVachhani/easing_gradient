import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';

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
    this.curve = Curves.easeInOut,
    this.direction = Axis.vertical,
    this.eased = true,
  });

  /// The widget whose edges are faded, usually a scrollable.
  final Widget child;

  /// Fraction of the long axis each fade covers, clamped to at most a half.
  final double extent;

  /// Shape of the alpha ramp. Ignored when [eased] is false.
  final Curve curve;

  /// Which pair of edges fades: top and bottom, or left and right.
  final Axis direction;

  /// Whether to build the mask with [EasingLinearGradient] or a plain
  /// [LinearGradient]. Present so the demo can show the two side by side.
  final bool eased;

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
    final double edge = extent.clamp(0.0, 0.5);
    if (edge == 0) return child;

    Gradient createMask(List<Color> colors) => eased
        ? EasingLinearGradient(
            begin: begin,
            end: end,
            colors: colors,
            curve: curve,
          )
        : LinearGradient(begin: begin, end: end, colors: colors);

    final Gradient leadingMask = createMask(leadingColors);
    final Gradient trailingMask = createMask(trailingColors);

    Rect leadingBounds(Rect bounds) => vertical
        ? Rect.fromLTWH(
            bounds.left,
            bounds.top,
            bounds.width,
            bounds.height * edge,
          )
        : Rect.fromLTWH(
            bounds.left,
            bounds.top,
            bounds.width * edge,
            bounds.height,
          );
    Rect trailingBounds(Rect bounds) => vertical
        ? Rect.fromLTWH(
            bounds.left,
            bounds.bottom - bounds.height * edge,
            bounds.width,
            bounds.height * edge,
          )
        : Rect.fromLTWH(
            bounds.right - bounds.width * edge,
            bounds.top,
            bounds.width * edge,
            bounds.height,
          );

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            Text('Edge fade', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Mask a scrollable with a gradient so its top and bottom edges '
              'dissolve into the background instead of being cut off.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _PreviewLayout(
              primary: _FadePreview(
                key: const ValueKey('edge-fade-preview-eased'),
                label: _enabled ? 'Eased mask' : 'No mask',
                detail: _enabled
                    ? 'EasingLinearGradient · ${_curve.name}'
                    : 'Content is clipped at the viewport edge',
                extent: _extent,
                curve: _curve.curve,
                enabled: _enabled,
                lightBackground: _lightBackground,
              ),
              secondary: _compare
                  ? _FadePreview(
                      key: const ValueKey('edge-fade-preview-linear'),
                      label: _enabled ? 'Linear mask' : 'No mask',
                      detail: _enabled
                          ? 'LinearGradient · no easing'
                          : 'Content is clipped at the viewport edge',
                      extent: _extent,
                      curve: _curve.curve,
                      enabled: _enabled,
                      eased: false,
                      lightBackground: _lightBackground,
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Black'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.light_mode),
                  label: Text('White'),
                ),
              ],
              selected: {_lightBackground},
              onSelectionChanged: (value) =>
                  setState(() => _lightBackground = value.first),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              title: const Text('Fade edges'),
              subtitle: const Text('Turn off to see the hard viewport edge'),
              onChanged: (value) => setState(() => _enabled = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _compare,
              title: const Text('Compare against a linear mask'),
              subtitle: const Text(
                'A linear alpha ramp creases where it meets the opaque middle',
              ),
              onChanged: (value) => setState(() => _compare = value),
            ),
            const SizedBox(height: 8),
            Text('Fade extent: ${(_extent * 100).round()}% of each edge'),
            Slider(
              value: _extent,
              max: 0.45,
              divisions: 45,
              label: '${(_extent * 100).round()}%',
              onChanged: (value) => setState(() => _extent = value),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<_FadeCurve>(
              initialValue: _curve,
              decoration: const InputDecoration(
                labelText: 'Curve',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final option in _fadeCurves)
                  DropdownMenuItem(value: option, child: Text(option.name)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _curve = value);
              },
            ),
            const SizedBox(height: 28),
            Text(
              'The recipe',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const _CodeBlock(_snippet),
            const SizedBox(height: 14),
            Text(
              'Build the gradient in build and pass createShader as the '
              'callback. ShaderMask asks for a shader on every paint, so '
              'constructing the gradient inside the callback would resample the '
              'curve on every frame of a scroll. Swap begin and end for '
              'centerLeft and centerRight to fade a horizontal list instead.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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

/// One masked scrollable plus its caption.
class _FadePreview extends StatelessWidget {
  const _FadePreview({
    super.key,
    required this.label,
    required this.detail,
    required this.extent,
    required this.curve,
    required this.enabled,
    required this.lightBackground,
    this.eased = true,
  });

  final String label;
  final String detail;
  final double extent;
  final Curve curve;
  final bool enabled;
  final bool lightBackground;
  final bool eased;

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
                  ? EdgeFade(
                      extent: extent,
                      curve: curve,
                      eased: eased,
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
      height: 56,
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
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

class _CodeBlock extends StatelessWidget {
  const _CodeBlock(this.code);
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF05070B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: <String>['Menlo', 'Consolas', 'Roboto Mono'],
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
