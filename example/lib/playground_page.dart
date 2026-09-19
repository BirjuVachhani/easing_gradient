import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';

import 'src/theme/tokens.dart';
import 'src/widgets/app_shell.dart';
import 'src/widgets/controls.dart';
import 'src/widgets/section.dart';

/// Named curve option shared by the Playground and the Accuracy Lab.
///
/// The registry intentionally spans linear, common smooth curves, a sharp
/// quintic curve, an overshooting curve, and hard steps. That set exercises the
/// distinct behaviors users need to inspect without listing every Flutter curve.
class CurveOption {
  const CurveOption(this.name, this.curve);

  final String name;
  final Curve curve;
}

const playgroundCurves = [
  CurveOption('Linear', Curves.linear),
  CurveOption('Ease in/out', Curves.easeInOut),
  CurveOption('Cubic', Curves.easeInOutCubic),
  CurveOption('Quint', Curves.easeInOutQuint),
  CurveOption('Elastic', Curves.elasticOut),
  CurveOption('Steps', StepsCurve(5, position: StepPosition.jumpNone)),
];

/// Interactive API matrix for geometry, easing, color space, and sample count.
///
/// Every control feeds the same compact source colors into each public gradient
/// type, showing that interpolation settings are independent of geometry.
class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  var _curve = playgroundCurves[1];
  var _space = EasingColorSpace.oklab;
  var _samples = 15;
  var _kind = 0;

  /// Purple to coral to soft orange, sampled from the Michelberger rooms page.
  static const colors = [
    Color(0xFFA78BF0),
    Color(0xFFEF6373),
    Color(0xFFF2A25C),
  ];

  Gradient get gradient => switch (_kind) {
    1 => EasingRadialGradient(
      colors: colors,
      curve: _curve.curve,
      colorSpace: _space,
      samplesPerTransition: _samples,
      radius: 0.8,
    ),
    2 => EasingSweepGradient(
      colors: colors,
      curve: _curve.curve,
      colorSpace: _space,
      samplesPerTransition: _samples,
    ),
    _ => EasingLinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      curve: _curve.curve,
      colorSpace: _space,
      samplesPerTransition: _samples,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final generated = easeColorStops(
      colors: colors,
      curve: _curve.curve,
      colorSpace: _space,
      samplesPerTransition: _samples,
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
                title: 'Playground',
                subtitle:
                    'One set of interpolation controls applied to linear, '
                    'radial, and sweep geometry. The curve and color space are '
                    'independent of the shape being painted.',
              ),
            ),
            Section(
              top: 32,
              child: DemoLayout(
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      // Tall enough to read the vertical fade end to end, but
                      // capped so the preview and its controls share a screen.
                      constraints: const BoxConstraints(maxHeight: 560),
                      child: AspectRatio(
                        aspectRatio: _kind == 0 ? 1.5 : 1.7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            gradient: gradient,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppBadge(
                          '${generated.colors.length} stops',
                          mono: true,
                        ),
                        AppBadge(_space.name, mono: true),
                        AppBadge(_curve.name),
                      ],
                    ),
                  ],
                ),
                controls: ControlPanel(
                  title: 'GRADIENT',
                  children: [
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Linear')),
                        ButtonSegment(value: 1, label: Text('Radial')),
                        ButtonSegment(value: 2, label: Text('Sweep')),
                      ],
                      selected: {_kind},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) =>
                          setState(() => _kind = value.first),
                    ),
                    const SizedBox(height: 18),
                    LabeledDropdown<CurveOption>(
                      label: 'Curve',
                      value: _curve,
                      values: playgroundCurves,
                      display: (option) => option.name,
                      onChanged: (option) => setState(() => _curve = option),
                    ),
                    const SizedBox(height: 16),
                    LabeledDropdown<EasingColorSpace>(
                      label: 'Color space',
                      value: _space,
                      values: EasingColorSpace.values,
                      display: (space) => space.name,
                      onChanged: (space) => setState(() => _space = space),
                    ),
                    const SizedBox(height: 18),
                    LabeledSlider(
                      label: 'Extra stops per transition',
                      value: _samples.toDouble(),
                      min: 1,
                      max: 63,
                      divisions: 62,
                      onChanged: (value) =>
                          setState(() => _samples = value.round()),
                    ),
                  ],
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
