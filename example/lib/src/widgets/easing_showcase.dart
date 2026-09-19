import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Where the photo starts dissolving, as a fraction of the card height.
const double _fadeStart = 0.15;

/// Where it has dissolved completely.
const double _fadeEnd = 0.75;

/// The morph between a straight ramp and [Curves.easeInOut].
///
/// Both are cubic beziers, so moving between them is just lerping the two
/// control points: `(0.25, 0.25, 0.75, 0.75)` lies on the diagonal and is the
/// identity, and `(0.42, 0, 0.58, 1)` is easeInOut. That keeps the slider
/// continuous and makes the readout an honest "how much easing" number.
Cubic _morph(double t) => Cubic(
  0.25 + (0.42 - 0.25) * t,
  0.25 + (0.00 - 0.25) * t,
  0.75 + (0.58 - 0.75) * t,
  0.75 + (1.00 - 0.75) * t,
);

/// The alpha mask that dissolves the photo into the card.
///
/// Only alpha survives [BlendMode.dstIn], so the opaque color is arbitrary.
/// The first two stops hold the photo fully opaque down to [_fadeStart]; the
/// ramp that follows is the thing being compared.
Gradient _mask({required bool eased, required Curve curve}) {
  const List<Color> colors = [Colors.black, Colors.black, Colors.transparent];
  const List<double> stops = [0, _fadeStart, _fadeEnd];
  return eased
      ? EasingLinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
          curve: curve,
          samplesPerTransition: 31,
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        );
}

/// The landing page's headline demo: one card built twice, differing only in
/// how its photo is faded out, with the curve under the reader's control.
class EasingShowcase extends StatefulWidget {
  const EasingShowcase({super.key});

  @override
  State<EasingShowcase> createState() => _EasingShowcaseState();
}

class _EasingShowcaseState extends State<EasingShowcase> {
  double _easing = 1;
  bool _guides = false;
  bool _underlay = false;

  @override
  Widget build(BuildContext context) {
    final curve = _morph(_easing);
    final cards = _CardPair(
      curve: curve,
      guides: _guides,
      underlay: _underlay,
      easing: _easing,
    );
    final controls = _Controls(
      easing: _easing,
      curve: curve,
      guides: _guides,
      underlay: _underlay,
      onEasing: (value) => setState(() => _easing = value),
      onGuides: (value) => setState(() => _guides = value),
      onUnderlay: (value) => setState(() => _underlay = value),
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 900
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(flex: 3, child: cards),
                const SizedBox(width: 40),
                Flexible(flex: 2, child: controls),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [cards, const SizedBox(height: 32), controls],
            ),
    );
  }
}

class _CardPair extends StatelessWidget {
  const _CardPair({
    required this.curve,
    required this.guides,
    required this.underlay,
    required this.easing,
  });

  final Curve curve;
  final bool guides;
  final bool underlay;
  final double easing;

  @override
  Widget build(BuildContext context) {
    // At zero easing both cards are the same gradient, so claiming one is
    // better would be a lie the reader can see through.
    final bool eased = easing > 0.02;
    final native = _TravelCard(
      eased: false,
      curve: curve,
      guides: guides,
      underlay: underlay,
      verdict: eased ? false : null,
      label: 'Basic linear',
    );
    final easedCard = _TravelCard(
      eased: true,
      curve: curve,
      guides: guides,
      underlay: underlay,
      verdict: eased ? true : null,
      label: eased ? 'Eased gradient' : 'Linear, for now',
    );
    // Below roughly 620 the pair would leave each card too narrow for its
    // caption, so they stack rather than shrink past legibility.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 620
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: native),
                const SizedBox(width: 20),
                Expanded(child: easedCard),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [native, const SizedBox(height: 28), easedCard],
            ),
    );
  }
}

/// A product card whose photograph is masked away toward its caption.
class _TravelCard extends StatelessWidget {
  const _TravelCard({
    required this.eased,
    required this.curve,
    required this.guides,
    required this.underlay,
    required this.verdict,
    required this.label,
  });

  final bool eased;
  final Curve curve;
  final bool guides;
  final bool underlay;

  /// True for the recommended side, false for the rejected one, null while the
  /// two are identical.
  final bool? verdict;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mask = _mask(eased: eased, curve: curve);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: mask.createShader,
                  // The underlay swaps the photo for flat ink, so the mask's
                  // own alpha ramp is visible as a plain tonal wedge.
                  child: underlay
                      ? ColoredBox(color: colors.foreground)
                      : Image.asset(
                          'assets/images/osaka.webp',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                ),
                if (guides)
                  CustomPaint(
                    painter: _GuidePainter(
                      color: const Color(0xFFE05252),
                      textColor: colors.mutedForeground,
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: _Caption(underlay: underlay),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (verdict != null) ...[
              Icon(
                verdict! ? Icons.check_rounded : Icons.close_rounded,
                size: 17,
                color: verdict! ? colors.accent : const Color(0xFFEF6068),
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The card's editorial block. Hidden behind the underlay, where the point is
/// the mask rather than the layout.
class _Caption extends StatelessWidget {
  const _Caption({required this.underlay});

  final bool underlay;

  @override
  Widget build(BuildContext context) {
    if (underlay) return const SizedBox.shrink();
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '48 HOURS IN',
            style: TextStyle(
              color: colors.link,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Osaka',
            style: TextStyle(
              color: colors.foreground,
              // A serif gives the card the editorial weight the demo is
              // imitating; the fallbacks cover platforms without Georgia.
              fontFamily: 'Georgia',
              fontFamilyFallback: const ['Times New Roman', 'serif'],
              fontSize: 30,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Neon nights, quiet shrines, and the best thing you have ever '
            'eaten at 2am.',
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: 10),
          // Flexible on both, because two cards side by side at phone width
          // leave each footer under 150 logical pixels.
          Row(
            children: [
              Flexible(
                child: Text(
                  '34.6937° N',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontFamily: AppFonts.mono,
                    fontSize: 9.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'JAPAN',
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dashed rules marking where the mask begins and finishes fading.
class _GuidePainter extends CustomPainter {
  const _GuidePainter({required this.color, required this.textColor});

  final Color color;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    _line(canvas, size, _fadeStart, 'start ${(_fadeStart * 100).round()}%');
    _line(canvas, size, _fadeEnd, 'end ${(_fadeEnd * 100).round()}%');
  }

  void _line(Canvas canvas, Size size, double fraction, String label) {
    final double y = size.height * fraction;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    for (double x = 8; x < size.width - 8; x += dash + gap) {
      final double end = (x + dash).clamp(0.0, size.width - 8);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          fontFamily: AppFonts.mono,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(10, y - painter.height - 2));
  }

  @override
  bool shouldRepaint(_GuidePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.textColor != textColor;
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.easing,
    required this.curve,
    required this.guides,
    required this.underlay,
    required this.onEasing,
    required this.onGuides,
    required this.onUnderlay,
  });

  final double easing;
  final Cubic curve;
  final bool guides;
  final bool underlay;
  final ValueChanged<double> onEasing;
  final ValueChanged<bool> onGuides;
  final ValueChanged<bool> onUnderlay;

  String get _snippet =>
      '''
EasingLinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: const [Colors.black, Colors.black, Colors.transparent],
  stops: const [0, $_fadeStart, $_fadeEnd],
  curve: const Cubic(${curve.a.toStringAsFixed(2)}, '''
      '''${curve.b.toStringAsFixed(2)}, ${curve.c.toStringAsFixed(2)}, '''
      '''${curve.d.toStringAsFixed(2)}),
)''';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'A little easing',
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(easing * 100).round()}%',
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontFamily: AppFonts.mono,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _CurvePainter(
                curve: curve,
                line: colors.foreground,
                reference: colors.mutedForeground,
                grid: colors.border,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              key: const ValueKey('showcase-easing'),
              value: easing,
              onChanged: onEasing,
            ),
          ),
          Row(
            children: [
              Text(
                'linear',
                style: TextStyle(color: colors.mutedForeground, fontSize: 11.5),
              ),
              const Spacer(),
              Text(
                'eased',
                style: TextStyle(color: colors.mutedForeground, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToggleChip(
                label: 'Stop guides',
                icon: Icons.straighten_rounded,
                value: guides,
                onChanged: onGuides,
              ),
              _ToggleChip(
                label: 'Show underlay',
                icon: Icons.layers_outlined,
                value: underlay,
                onChanged: onUnderlay,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            underlay
                ? 'With the photo swapped for flat ink you can read the mask '
                      'directly. Watch where each side arrives at solid.'
                : 'The photo, the stops and the card are identical on both '
                      'sides. What changes is the ramp between the stops.',
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _CopyButton(snippet: _snippet),
        ],
      ),
    );
  }
}

/// Plots the live curve against a straight reference.
class _CurvePainter extends CustomPainter {
  const _CurvePainter({
    required this.curve,
    required this.line,
    required this.reference,
    required this.grid,
  });

  final Cubic curve;
  final Color line;
  final Color reference;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      frame,
    );

    // The straight ramp, drawn dashed so the eased curve can be read against
    // the thing it departs from.
    final dashed = Paint()
      ..color = reference.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const steps = 34;
    for (var i = 0; i < steps; i += 2) {
      final double x0 = size.width * (i / steps);
      final double x1 = size.width * ((i + 1) / steps);
      canvas.drawLine(
        Offset(x0, size.height - size.height * (i / steps)),
        Offset(x1, size.height - size.height * ((i + 1) / steps)),
        dashed,
      );
    }

    final path = Path()..moveTo(0, size.height);
    const samples = 96;
    for (var i = 1; i <= samples; i++) {
      final double t = i / samples;
      path.lineTo(
        size.width * t,
        size.height - size.height * curve.transform(t),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CurvePainter oldDelegate) =>
      oldDelegate.curve != curve ||
      oldDelegate.line != line ||
      oldDelegate.reference != reference;
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: value ? colors.primary : colors.surfaceInset,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: value ? colors.onPrimary : colors.mutedForeground,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: value ? colors.onPrimary : colors.foreground,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.snippet});

  final String snippet;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.snippet));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SelectionContainer.disabled(
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _copy,
          icon: Icon(
            _copied ? Icons.check_rounded : Icons.copy_rounded,
            size: 15,
          ),
          label: Text(_copied ? 'Copied' : 'Copy this gradient'),
          style: TextButton.styleFrom(
            foregroundColor: _copied ? colors.accent : colors.foreground,
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(fontSize: 13.5),
          ),
        ),
      ),
    );
  }
}
