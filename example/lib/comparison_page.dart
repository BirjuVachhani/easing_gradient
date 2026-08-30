import 'dart:math' as math;

import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';

/// A browsable catalog comparing native and eased gradient behavior.
class ComparisonPage extends StatelessWidget {
  const ComparisonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          key: const PageStorageKey('comparison-catalog-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            Text(
              'Gradient comparison gallery',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Eighteen fixed examples covering curves, color spaces, '
              'transparency, stops, geometry, hard bands and sample density.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 30),
            for (var index = 0; index < _catalog.length; index++) ...[
              _ComparisonSectionView(section: _catalog[index]),
              if (index != _catalog.length - 1) const SizedBox(height: 42),
            ],
          ],
        ),
      ),
    );
  }
}

/// Presentation fixtures chosen to expose a particular gradient property.
///
/// These are not gradient algorithms. Scrims reveal seam visibility, swatches
/// show color paths, checkerboards expose hidden transparent RGB, shallow bands
/// make duplicated hard stops legible, and geometry previews reserve enough
/// area for radial and sweep shapes.
enum _PreviewMode { scrim, swatch, transparency, bands, geometry }

/// One teaching chapter in the fixed comparison catalog.
///
/// Stable [id] values drive widget-test keys, while copy and renderable samples
/// stay separate so wording can evolve without changing test identity.
class _ComparisonSection {
  const _ComparisonSection({
    required this.id,
    required this.title,
    required this.description,
    required this.cases,
  });

  final String id;
  final String title;
  final String description;
  final List<_GradientComparison> cases;
}

/// A paired visual claim within a [_ComparisonSection].
///
/// The sides are deliberately generic rather than native/eased: many examples
/// compare two curves, color spaces, step positions, or sample densities.
class _GradientComparison {
  const _GradientComparison({
    required this.id,
    required this.title,
    required this.description,
    required this.mode,
    required this.left,
    required this.right,
  });

  final String id;
  final String title;
  final String description;
  final _PreviewMode mode;
  final _GradientSample left;
  final _GradientSample right;
}

class _GradientSample {
  const _GradientSample({
    required this.label,
    required this.detail,
    required this.gradient,
  });

  final String label;
  final String detail;
  final Gradient gradient;
}

/// Ordered curriculum covering every public gradient type and configuration
/// family without duplicating Playground's interactive controls.
///
/// Keep the six section IDs and representative final case stable because widget
/// tests use them to prove that the lazy list remains complete and scrollable.
final List<_ComparisonSection> _catalog = [
  _ComparisonSection(
    id: 'basics',
    title: '01  Easing fundamentals',
    description: 'The colors can stay identical while the curve moves visual weight to a different part of the fade.',
    cases: [
      _GradientComparison(
        id: 'classic-scrim',
        title: 'Classic text scrim',
        description: 'The original use case: remove the hard seam where a dark overlay begins.',
        mode: _PreviewMode.scrim,
        left: const _GradientSample(
          label: 'Flutter',
          detail: 'LinearGradient',
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
          ),
        ),
        right: _GradientSample(
          label: 'Eased',
          detail: 'Curves.easeInOut · OKLab',
          gradient: EasingLinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Colors.transparent, Colors.black],
          ),
        ),
      ),
      _GradientComparison(
        id: 'curve-pacing',
        title: 'Linear versus ease-in-out',
        description: 'Both sides use sRGB. Only the curve changes, so this is a strict pacing comparison.',
        mode: _PreviewMode.swatch,
        left: _GradientSample(
          label: 'Linear',
          detail: 'Curves.linear · sRGB',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF111827), Color(0xFF60A5FA)],
            curve: Curves.linear,
            colorSpace: EasingColorSpace.srgb,
          ),
        ),
        right: _GradientSample(
          label: 'Ease in/out',
          detail: 'Curves.easeInOut · sRGB',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF111827), Color(0xFF60A5FA)],
            colorSpace: EasingColorSpace.srgb,
          ),
        ),
      ),
      _GradientComparison(
        id: 'ease-direction',
        title: 'Ease-in versus ease-out',
        description: 'Ease-in holds the first color longer. Ease-out reaches the second color sooner.',
        mode: _PreviewMode.swatch,
        left: _GradientSample(
          label: 'Ease in',
          detail: 'Curves.easeInCubic',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFFEC4899), Color(0xFF312E81)],
            curve: Curves.easeInCubic,
          ),
        ),
        right: _GradientSample(
          label: 'Ease out',
          detail: 'Curves.easeOutCubic',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFFEC4899), Color(0xFF312E81)],
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    ],
  ),
  _ComparisonSection(
    id: 'color',
    title: '02  Transparency and color spaces',
    description: 'Color space decides the route between endpoints. Premultiplied alpha keeps transparent fades clean.',
    cases: [
      _GradientComparison(
        id: 'transparent-white',
        title: 'Clean transparent white',
        description: 'The checkerboard exposes hidden RGB contamination near a transparent endpoint.',
        mode: _PreviewMode.transparency,
        left: const _GradientSample(
          label: 'Native',
          detail: 'white → Colors.transparent',
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0x00000000)],
          ),
        ),
        right: _GradientSample(
          label: 'Premultiplied',
          detail: 'white stays white while alpha falls',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFFFFFFFF), Color(0x00000000)],
            curve: Curves.linear,
            colorSpace: EasingColorSpace.srgb,
          ),
        ),
      ),
      _GradientComparison(
        id: 'srgb-linear',
        title: 'sRGB versus linear light',
        description: 'Linear RGB mixes emitted light and avoids the dark midpoint of display-encoded sRGB.',
        mode: _PreviewMode.swatch,
        left: _GradientSample(
          label: 'sRGB',
          detail: 'EasingColorSpace.srgb',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFFFF0000), Color(0xFF00FF00)],
            curve: Curves.linear,
            colorSpace: EasingColorSpace.srgb,
          ),
        ),
        right: _GradientSample(
          label: 'Linear light',
          detail: 'EasingColorSpace.linearRgb',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFFFF0000), Color(0xFF00FF00)],
            curve: Curves.linear,
            colorSpace: EasingColorSpace.linearRgb,
          ),
        ),
      ),
      _GradientComparison(
        id: 'oklab-oklch',
        title: 'OKLab versus OKLCH',
        description: 'OKLab takes a perceptual straight line. OKLCH explicitly sweeps hue along the shorter arc.',
        mode: _PreviewMode.swatch,
        left: _GradientSample(
          label: 'OKLab',
          detail: 'EasingColorSpace.oklab',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF2563EB), Color(0xFFFACC15)],
          ),
        ),
        right: _GradientSample(
          label: 'OKLCH',
          detail: 'EasingColorSpace.oklch',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF2563EB), Color(0xFFFACC15)],
            colorSpace: EasingColorSpace.oklch,
          ),
        ),
      ),
      _GradientComparison(
        id: 'hsl-oklch',
        title: 'HSL versus OKLCH',
        description: 'Both interpolate hue directly, but only OKLCH aims for perceptually even steps.',
        mode: _PreviewMode.swatch,
        left: _GradientSample(
          label: 'HSL',
          detail: 'EasingColorSpace.hsl',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFFF43F5E), Color(0xFF06B6D4)],
            colorSpace: EasingColorSpace.hsl,
          ),
        ),
        right: _GradientSample(
          label: 'OKLCH',
          detail: 'EasingColorSpace.oklch',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFFF43F5E), Color(0xFF06B6D4)],
            colorSpace: EasingColorSpace.oklch,
          ),
        ),
      ),
    ],
  ),
  _ComparisonSection(
    id: 'stops',
    title: '03  Stops and transitions',
    description: 'Compact source colors can use custom positions and a separate curve for every transition.',
    cases: [
      _GradientComparison(
        id: 'multi-stop',
        title: 'Multi-stop palette',
        description: 'Every neighboring pair is sampled independently and shares its boundary exactly once.',
        mode: _PreviewMode.swatch,
        left: const _GradientSample(
          label: 'Native',
          detail: 'Four compact stops',
          gradient: LinearGradient(
            colors: [
              Color(0xFF7C3AED),
              Color(0xFFEC4899),
              Color(0xFFF59E0B),
              Color(0xFF10B981),
            ],
          ),
        ),
        right: _GradientSample(
          label: 'Eased',
          detail: 'Three eased transitions',
          gradient: EasingLinearGradient(
            colors: const [
              Color(0xFF7C3AED),
              Color(0xFFEC4899),
              Color(0xFFF59E0B),
              Color(0xFF10B981),
            ],
          ),
        ),
      ),
      _GradientComparison(
        id: 'transition-curves',
        title: 'A curve per transition',
        description: 'Overrides shape selected segments while null falls back to the global curve.',
        mode: _PreviewMode.swatch,
        left: _GradientSample(
          label: 'One curve',
          detail: 'easeInOut everywhere',
          gradient: EasingLinearGradient(
            colors: const [
              Color(0xFF0F172A),
              Color(0xFF38BDF8),
              Color(0xFFFDE047),
              Color(0xFFEF4444),
            ],
          ),
        ),
        right: _GradientSample(
          label: 'Per transition',
          detail: 'easeOut · fallback · easeIn',
          gradient: EasingLinearGradient(
            colors: const [
              Color(0xFF0F172A),
              Color(0xFF38BDF8),
              Color(0xFFFDE047),
              Color(0xFFEF4444),
            ],
            transitionCurves: const [
              Curves.easeOutCubic,
              null,
              Curves.easeInCubic,
            ],
          ),
        ),
      ),
      _GradientComparison(
        id: 'custom-stops',
        title: 'Custom source positions',
        description: 'Nonuniform source stops cluster color events while easing still operates inside each segment.',
        mode: _PreviewMode.swatch,
        left: _GradientSample(
          label: 'Even',
          detail: 'Implied source stops',
          gradient: EasingLinearGradient(
            colors: const [
              Color(0xFF172554),
              Color(0xFF22D3EE),
              Color(0xFFF8FAFC),
            ],
          ),
        ),
        right: _GradientSample(
          label: 'Clustered',
          detail: 'stops: 0.0 · 0.2 · 1.0',
          gradient: EasingLinearGradient(
            colors: const [
              Color(0xFF172554),
              Color(0xFF22D3EE),
              Color(0xFFF8FAFC),
            ],
            stops: const [0, 0.2, 1],
          ),
        ),
      ),
    ],
  ),
  _ComparisonSection(
    id: 'steps',
    title: '04  Hard bands',
    description: 'StepsCurve emits duplicated native stops, producing exact bands rather than very short ramps.',
    cases: [
      _GradientComparison(
        id: 'step-edges',
        title: 'Steps at the edges',
        description: 'jumpStart raises the first band; jumpEnd preserves the start band.',
        mode: _PreviewMode.bands,
        left: _GradientSample(
          label: 'jumpStart',
          detail: 'StepPosition.jumpStart',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF111827), Color(0xFFF97316)],
            curve: const StepsCurve(5, position: StepPosition.jumpStart),
          ),
        ),
        right: _GradientSample(
          label: 'jumpEnd',
          detail: 'StepPosition.jumpEnd',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF111827), Color(0xFFF97316)],
            curve: const StepsCurve(5, position: StepPosition.jumpEnd),
          ),
        ),
      ),
      _GradientComparison(
        id: 'step-inner',
        title: 'Steps inside the range',
        description: 'jumpBoth skips endpoint bands; jumpNone shows both endpoints as full bands.',
        mode: _PreviewMode.bands,
        left: _GradientSample(
          label: 'jumpBoth',
          detail: 'StepPosition.jumpBoth',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF4C1D95), Color(0xFF34D399)],
            curve: const StepsCurve(5, position: StepPosition.jumpBoth),
          ),
        ),
        right: _GradientSample(
          label: 'jumpNone',
          detail: 'StepPosition.jumpNone',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF4C1D95), Color(0xFF34D399)],
            curve: const StepsCurve(5, position: StepPosition.jumpNone),
          ),
        ),
      ),
    ],
  ),
  _ComparisonSection(
    id: 'geometry',
    title: '05  Gradient geometry',
    description: 'Easing is independent of shape. Linear, radial, focal and sweep geometry use Flutter’s native shaders.',
    cases: [
      _GradientComparison(
        id: 'diagonal',
        title: 'Diagonal linear direction',
        description: 'Begin, end and transform pass directly through to the parent LinearGradient.',
        mode: _PreviewMode.geometry,
        left: const _GradientSample(
          label: 'Native diagonal',
          detail: 'topLeft → bottomRight',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111827), Color(0xFF8B5CF6), Color(0xFFF472B6)],
          ),
        ),
        right: _GradientSample(
          label: 'Eased + rotated',
          detail: 'GradientRotation(0.22)',
          gradient: EasingLinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0xFF111827),
              Color(0xFF8B5CF6),
              Color(0xFFF472B6),
            ],
            transform: const GradientRotation(0.22),
          ),
        ),
      ),
      _GradientComparison(
        id: 'radial',
        title: 'Radial glow',
        description: 'A non-default center and radius work exactly like Flutter’s RadialGradient.',
        mode: _PreviewMode.geometry,
        left: const _GradientSample(
          label: 'Native radial',
          detail: 'center: topLeft',
          gradient: RadialGradient(
            center: Alignment(-0.55, -0.55),
            radius: 1.0,
            colors: [Color(0xFFFFFFFF), Color(0xFF38BDF8), Color(0x001D4ED8)],
          ),
        ),
        right: _GradientSample(
          label: 'Eased radial',
          detail: 'easeOutCubic · OKLab',
          gradient: EasingRadialGradient(
            center: const Alignment(-0.55, -0.55),
            radius: 1,
            colors: const [
              Color(0xFFFFFFFF),
              Color(0xFF38BDF8),
              Color(0x001D4ED8),
            ],
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
      _GradientComparison(
        id: 'focal',
        title: 'Focal radial light',
        description: 'A focal point and radius pull the gradient toward a directional light source.',
        mode: _PreviewMode.geometry,
        left: _GradientSample(
          label: 'Centered',
          detail: 'No focal point',
          gradient: EasingRadialGradient(
            radius: 0.8,
            colors: const [
              Color(0xFFFFFBEB),
              Color(0xFFF59E0B),
              Color(0x00120A02),
            ],
          ),
        ),
        right: _GradientSample(
          label: 'Focal',
          detail: 'focal: topLeft · radius: 0.08',
          gradient: EasingRadialGradient(
            center: const Alignment(0.25, 0.15),
            radius: 0.9,
            focal: const Alignment(-0.45, -0.45),
            focalRadius: 0.08,
            colors: const [
              Color(0xFFFFFBEB),
              Color(0xFFF59E0B),
              Color(0x00120A02),
            ],
          ),
        ),
      ),
      _GradientComparison(
        id: 'sweep',
        title: 'Sweep arc',
        description: 'A partial arc demonstrates center and angle passthrough with eased OKLCH colors.',
        mode: _PreviewMode.geometry,
        left: const _GradientSample(
          label: 'Native sweep',
          detail: 'Full circle',
          gradient: SweepGradient(
            colors: [
              Color(0xFFEC4899),
              Color(0xFF8B5CF6),
              Color(0xFF06B6D4),
              Color(0xFFEC4899),
            ],
          ),
        ),
        right: _GradientSample(
          label: 'Eased arc',
          detail: '45° → 315° · OKLCH',
          gradient: EasingSweepGradient(
            center: const Alignment(0.15, -0.1),
            startAngle: math.pi / 4,
            endAngle: math.pi * 7 / 4,
            colors: const [
              Color(0xFFEC4899),
              Color(0xFF8B5CF6),
              Color(0xFF06B6D4),
              Color(0xFFEC4899),
            ],
            colorSpace: EasingColorSpace.oklch,
          ),
        ),
      ),
    ],
  ),
  _ComparisonSection(
    id: 'density',
    title: '06  Sample density',
    description: 'Samples are computed once at construction. More stops improve sharp curves without per-frame curve work.',
    cases: [
      _GradientComparison(
        id: 'coarse-default',
        title: 'Coarse versus default',
        description: 'Three extra stops reveal the low-poly approximation. Fifteen is the package default.',
        mode: _PreviewMode.swatch,
        left: _GradientSample(
          label: 'Coarse',
          detail: 'samplesPerTransition: 3',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF0F172A), Color(0xFF22D3EE)],
            curve: Curves.easeInOutCubic,
            samplesPerTransition: 3,
          ),
        ),
        right: _GradientSample(
          label: 'Default',
          detail: 'samplesPerTransition: $defaultSamplesPerTransition',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF0F172A), Color(0xFF22D3EE)],
            curve: Curves.easeInOutCubic,
          ),
        ),
      ),
      _GradientComparison(
        id: 'default-high',
        title: 'Default versus high fidelity',
        description: 'Sharp quintic pacing benefits from 31 stops. Accuracy Lab quantifies the remaining error.',
        mode: _PreviewMode.swatch,
        left: _GradientSample(
          label: 'Default',
          detail: '15 samples · easeInOutQuint',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF1E1B4B), Color(0xFFFDE047)],
            curve: Curves.easeInOutQuint,
          ),
        ),
        right: _GradientSample(
          label: 'High fidelity',
          detail: '31 samples · easeInOutQuint',
          gradient: EasingLinearGradient(
            colors: const [Color(0xFF1E1B4B), Color(0xFFFDE047)],
            curve: Curves.easeInOutQuint,
            samplesPerTransition: 31,
          ),
        ),
      ),
    ],
  ),
];

class _ComparisonSectionView extends StatelessWidget {
  const _ComparisonSectionView({required this.section});
  final _ComparisonSection section;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey('compare-section-${section.id}'),
      container: true,
      label: '${section.title}. ${section.description}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            section.title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            section.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < section.cases.length; index++) ...[
            _ComparisonCaseView(comparison: section.cases[index]),
            if (index != section.cases.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _ComparisonCaseView extends StatelessWidget {
  const _ComparisonCaseView({required this.comparison});
  final _GradientComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('compare-case-${comparison.id}'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              comparison.title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              comparison.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _ResponsiveGradientPair(comparison: comparison),
          ],
        ),
      ),
    );
  }
}

/// Lays out two preview cards at the minimum width needed for legible labels.
///
/// The 700 logical-pixel threshold is based on two roughly 330-pixel cards plus
/// their gap inside the case padding, rather than on a device category.
class _ResponsiveGradientPair extends StatelessWidget {
  const _ResponsiveGradientPair({required this.comparison});
  final _GradientComparison comparison;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700;
        final left = _GradientPreviewCard(
          key: ValueKey('compare-case-${comparison.id}-left'),
          sample: comparison.left,
          mode: comparison.mode,
        );
        final right = _GradientPreviewCard(
          key: ValueKey('compare-case-${comparison.id}-right'),
          sample: comparison.right,
          mode: comparison.mode,
        );
        return horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 16),
                  Expanded(child: right),
                ],
              )
            : Column(children: [left, const SizedBox(height: 14), right]);
      },
    );
  }
}

/// Applies diagnostic framing and aspect ratio to one gradient sample.
///
/// Scrims use an image-like canvas, bands use a shallow strip, and geometry
/// previews need extra height to reveal centers, radii, and sweep angles.
class _GradientPreviewCard extends StatelessWidget {
  const _GradientPreviewCard({
    super.key,
    required this.sample,
    required this.mode,
  });
  final _GradientSample sample;
  final _PreviewMode mode;

  double get _aspectRatio => switch (mode) {
    _PreviewMode.scrim => 16 / 9,
    _PreviewMode.bands => 4.2,
    _PreviewMode.geometry => 2.1,
    _PreviewMode.swatch || _PreviewMode.transparency => 3.2,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${sample.label}. ${sample.detail}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: _aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _PreviewSurface(sample: sample, mode: mode),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            sample.label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            sample.detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({required this.sample, required this.mode});
  final _GradientSample sample;
  final _PreviewMode mode;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      _PreviewMode.scrim => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.75, -0.8),
                radius: 1.45,
                colors: [
                  Color(0xFFFFB36B),
                  Color(0xFF6D5EF7),
                  Color(0xFF14213D),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.78,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: sample.gradient),
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Text(
              'Readable text without a visible seam',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      _PreviewMode.transparency => Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _CheckerboardPainter()),
          DecoratedBox(decoration: BoxDecoration(gradient: sample.gradient)),
        ],
      ),
      _PreviewMode.geometry => DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF05070B)),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: sample.gradient),
          ),
        ),
      ),
      _PreviewMode.swatch || _PreviewMode.bands => DecoratedBox(
        decoration: BoxDecoration(gradient: sample.gradient),
      ),
    };
  }
}

/// Neutral transparency backdrop used to reveal hidden-RGB contamination.
///
/// Sixteen-pixel cells remain visible at both narrow and wide preview sizes
/// without competing with the gradient itself.
class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 16.0;
    final paint = Paint();
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        final dark = ((x / cell).floor() + (y / cell).floor()).isOdd;
        paint.color = dark ? const Color(0xFF374151) : const Color(0xFF9CA3AF);
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) => false;
}
