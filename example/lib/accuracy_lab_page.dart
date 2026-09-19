import 'dart:math' as math;

import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';

import 'benchmark/sampling.dart';
import 'src/theme/tokens.dart';
import 'src/widgets/app_shell.dart';
import 'src/widgets/controls.dart';
import 'src/widgets/section.dart';

const _presets = <({String name, Color from, Color to, Color background})>[
  (
    name: 'Black fade on white',
    from: Colors.black,
    to: Colors.transparent,
    background: Colors.white,
  ),
  (
    name: 'White fade on black',
    from: Colors.white,
    to: Color(0x00FFFFFF),
    background: Colors.black,
  ),
  (
    name: 'Shallow gray ramp',
    from: Color(0xFF202020),
    to: Color(0xFF303030),
    background: Colors.black,
  ),
  (
    name: 'Chromatic fade',
    from: Color(0xFF4F46E5),
    to: Color(0x00F97316),
    background: Colors.white,
  ),
  (
    name: 'Blue to yellow',
    from: Color(0xFF2563EB),
    to: Color(0xFFFACC15),
    background: Colors.black,
  ),
];

const _curves = <String, Curve>{
  'Linear': Curves.linear,
  'Ease in/out': Curves.easeInOut,
  'Quint': Curves.easeInOutQuint,
  'Elastic': Curves.elasticOut,
};

/// Compares sampling models separately from native rendering and display banding.
class AccuracyLabPage extends StatefulWidget {
  const AccuracyLabPage({super.key});

  @override
  State<AccuracyLabPage> createState() => _AccuracyLabPageState();
}

class _AccuracyLabPageState extends State<AccuracyLabPage> {
  int _preset = 0;
  String _curveName = 'Ease in/out';
  EasingColorSpace _space = EasingColorSpace.oklab;
  SamplingStrategy _strategy = SamplingStrategy.adaptive;
  int _samples = 15;
  double _amplification = 32;

  @override
  Widget build(BuildContext context) {
    final preset = _presets[_preset];
    final curve = _curves[_curveName]!;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    EasedColorStops generate(SamplingStrategy strategy, int samples) =>
        sampleGradient(
          from: preset.from,
          to: preset.to,
          curve: curve,
          space: _space,
          samples: samples,
          strategy: strategy,
        );
    final uniform = generate(SamplingStrategy.uniform, _samples);
    final candidate = generate(_strategy, _samples);
    final dense = generate(SamplingStrategy.uniform, 255);
    Color reference(double t) =>
        mixColors(preset.from, preset.to, curve.transform(t), _space);
    final error = measureSamplingError(
      from: preset.from,
      to: preset.to,
      curve: curve,
      space: _space,
      generated: candidate,
    );
    Widget native(EasedColorStops stops) => DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: stops.colors, stops: stops.stops),
      ),
    );
    Widget strip(String label, String detail, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.colors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detail,
                  style: TextStyle(
                    color: context.colors.mutedForeground,
                    fontFamily: AppFonts.mono,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: SizedBox(
              height: 92,
              child: ColoredBox(color: preset.background, child: child),
            ),
          ),
        ],
      ),
    );
    final controls = ControlPanel(
      title: 'FIXTURE',
      children: [
        LabeledDropdown<int>(
          key: const ValueKey('accuracy-preset'),
          label: 'Preset',
          value: _preset,
          values: [for (var i = 0; i < _presets.length; i++) i],
          display: (index) => _presets[index].name,
          onChanged: (index) => setState(() => _preset = index),
        ),
        const SizedBox(height: 16),
        LabeledDropdown<String>(
          label: 'Curve',
          value: _curveName,
          values: _curves.keys.toList(),
          display: (name) => name,
          onChanged: (name) => setState(() => _curveName = name),
        ),
        const SizedBox(height: 16),
        LabeledDropdown<EasingColorSpace>(
          label: 'Interpolation',
          value: _space,
          values: EasingColorSpace.values,
          display: (space) => space.name,
          onChanged: (space) => setState(() => _space = space),
        ),
        const SizedBox(height: 16),
        LabeledDropdown<SamplingStrategy>(
          key: const ValueKey('accuracy-strategy'),
          label: 'Experimental placement',
          value: _strategy,
          values: SamplingStrategy.values,
          display: (strategy) => strategy.name,
          onChanged: (strategy) => setState(() => _strategy = strategy),
        ),
        if (_strategy == SamplingStrategy.bezier && curve is! Cubic) ...[
          const SizedBox(height: 10),
          Text(
            'Bezier placement needs a Cubic. This curve falls back to uniform.',
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 20),
        LabeledSlider(
          key: const ValueKey('accuracy-samples'),
          label: 'Interior sample budget',
          value: _samples.toDouble(),
          min: 1,
          max: 63,
          divisions: 62,
          onChanged: (value) => setState(() => _samples = value.round()),
        ),
        const SizedBox(height: 18),
        LabeledSlider(
          label: 'Residual amplification',
          value: _amplification,
          min: 1,
          max: 128,
          divisions: 127,
          valueLabel: '${_amplification.round()}x',
          onChanged: (value) => setState(() => _amplification = value),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.surfaceInset,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MODEL ERROR (x255)',
                style: TextStyle(
                  color: context.colors.mutedForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              for (final row in [
                ('max', error.maximum),
                ('p95', error.p95),
                ('rms', error.rms),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row.$1,
                        style: TextStyle(
                          color: context.colors.mutedForeground,
                          fontFamily: AppFonts.mono,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        (row.$2 * 255).toStringAsFixed(3),
                        style: TextStyle(
                          color: context.colors.foreground,
                          fontFamily: AppFonts.mono,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Includes alpha and black/white compositing. A CPU model, not a '
                'perceptual threshold and not a framebuffer measurement.',
                style: TextStyle(
                  color: context.colors.mutedForeground,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final strips = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        strip(
          'Uniform native',
          '${uniform.stops.length} stops',
          native(uniform),
        ),
        strip(
          '${_strategy.name} native',
          '${candidate.stops.length} stops',
          native(candidate),
        ),
        strip(
          'Dense uniform native',
          '${dense.stops.length} stops (255 interior)',
          native(dense),
        ),
        strip(
          'CPU reference',
          'nonoverlapping physical columns, DPR ${dpr.toStringAsFixed(2)}',
          CustomPaint(
            painter: ReferenceStripPainter(
              evaluate: reference,
              background: preset.background,
              devicePixelRatio: dpr,
            ),
          ),
        ),
        strip(
          'CPU composite and alpha residual',
          'amplified ${_amplification.round()}x',
          CustomPaint(
            painter: ReferenceStripPainter(
              evaluate: (t) {
                final difference = compositeError(
                  reference(t),
                  sampleStops(candidate, t),
                  background: preset.background,
                );
                final value = (difference * _amplification).clamp(0.0, 1.0);
                return Color.from(
                  alpha: 1,
                  red: value,
                  green: value,
                  blue: value,
                );
              },
              background: Colors.black,
              devicePixelRatio: dpr,
            ),
          ),
        ),
      ],
    );

    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Section(
              top: AppLayout.navHeight + (context.isCompact ? 40 : 64),
              bottom: 0,
              child: const PageHeading(
                title: 'Accuracy Lab',
                subtitle:
                    'Native strips are painted by Flutter shaders. The '
                    'reference and residual are CPU models, so they isolate '
                    'stop placement. They are not framebuffer measurements and '
                    'not a guarantee of band-free output on any display.',
              ),
            ),
            Section(
              top: 32,
              bottom: 0,
              child: DemoLayout(preview: strips, controls: controls),
            ),
            Section(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.readingMaxWidth,
                ),
                child: Text(
                  'The reference and the sampled colors share the package '
                  'mixer, so these comparisons isolate stop placement rather '
                  'than validating color conversion independently. A screenshot '
                  'also cannot capture the full monitor output path.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }
}

/// Paints an opaque, source-over CPU model without overlapping alpha strokes.
///
/// Pixel-center evaluations model a horizontal gradient across the full bounds.
/// The reference still passes through the backend and is not a display oracle.
class ReferenceStripPainter extends CustomPainter {
  const ReferenceStripPainter({
    required this.evaluate,
    required this.background,
    required this.devicePixelRatio,
  });

  final Color Function(double) evaluate;
  final Color background;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final width = size.width * devicePixelRatio;
    final columns = width.ceil();
    final paint = Paint()..isAntiAlias = false;
    for (var x = 0; x < columns; x++) {
      final color = evaluate(((x + 0.5) / width).clamp(0.0, 1.0));
      final alpha = color.a;
      paint.color = Color.from(
        alpha: 1,
        red: color.r * alpha + background.r * (1 - alpha),
        green: color.g * alpha + background.g * (1 - alpha),
        blue: color.b * alpha + background.b * (1 - alpha),
      );
      canvas.drawRect(
        Rect.fromLTRB(
          x / devicePixelRatio,
          0,
          math.min((x + 1) / devicePixelRatio, size.width),
          size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ReferenceStripPainter oldDelegate) =>
      evaluate != oldDelegate.evaluate ||
      background != oldDelegate.background ||
      devicePixelRatio != oldDelegate.devicePixelRatio;
}
