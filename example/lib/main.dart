import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';

import 'comparison_page.dart';

void main() => runApp(const EasingGradientDemo());

class EasingGradientDemo extends StatelessWidget {
  const EasingGradientDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Easing Gradient Lab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D5EF7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.onDrag,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF17181E),
          margin: EdgeInsets.zero,
        ),
      ),
      home: const _DemoHome(),
    );
  }
}

class _DemoHome extends StatefulWidget {
  const _DemoHome();

  @override
  State<_DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<_DemoHome> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const ComparisonPage(),
      const _PlaygroundPage(),
      const _AccuracyLabPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easing Gradient Lab'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.compare), label: 'Compare'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Playground'),
          NavigationDestination(icon: Icon(Icons.science), label: 'Accuracy'),
        ],
      ),
    );
  }
}

/// Named curve option shared by Playground and Accuracy Lab.
///
/// The registry below intentionally spans linear, common smooth curves, a sharp
/// quintic curve, an overshooting curve, and hard steps. That set exercises the
/// distinct behaviors users need to inspect without listing every Flutter curve.
class _CurveOption {
  const _CurveOption(this.name, this.curve);
  final String name;
  final Curve curve;
}

const _curves = [
  _CurveOption('Linear', Curves.linear),
  _CurveOption('Ease in/out', Curves.easeInOut),
  _CurveOption('Cubic', Curves.easeInOutCubic),
  _CurveOption('Quint', Curves.easeInOutQuint),
  _CurveOption('Elastic', Curves.elasticOut),
  _CurveOption('Steps', StepsCurve(5, position: StepPosition.jumpNone)),
];

class _PlaygroundPage extends StatefulWidget {
  const _PlaygroundPage();

  @override
  State<_PlaygroundPage> createState() => _PlaygroundPageState();
}

/// Interactive API matrix for geometry, easing, color space, and sample count.
///
/// All controls feed the same compact source colors into each public gradient
/// type, demonstrating that interpolation settings are independent of geometry.
class _PlaygroundPageState extends State<_PlaygroundPage> {
  var _curve = _curves[1];
  var _space = EasingColorSpace.oklab;
  var _samples = 15;
  var _kind = 0;

  Gradient get gradient {
    const colors = [Color(0xFFEF4444), Color(0xFF3B82F6), Color(0x0010B981)];
    return switch (_kind) {
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
        colors: colors,
        curve: _curve.curve,
        colorSpace: _space,
        samplesPerTransition: _samples,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Playground', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Linear')),
            ButtonSegment(value: 1, label: Text('Radial')),
            ButtonSegment(value: 2, label: Text('Sweep')),
          ],
          selected: {_kind},
          onSelectionChanged: (value) => setState(() => _kind = value.first),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 2.8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: gradient,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Dropdown<_CurveOption>(
          label: 'Curve',
          value: _curve,
          values: _curves,
          display: (v) => v.name,
          onChanged: (v) => setState(() => _curve = v),
        ),
        const SizedBox(height: 12),
        _Dropdown<EasingColorSpace>(
          label: 'Color space',
          value: _space,
          values: EasingColorSpace.values,
          display: (v) => v.name,
          onChanged: (v) => setState(() => _space = v),
        ),
        const SizedBox(height: 12),
        Text('Extra stops per transition: $_samples'),
        Slider(
          value: _samples.toDouble(),
          min: 1,
          max: 63,
          divisions: 62,
          label: '$_samples',
          onChanged: (v) => setState(() => _samples = v.round()),
        ),
      ],
    );
  }
}

class _AccuracyLabPage extends StatefulWidget {
  const _AccuracyLabPage();

  @override
  State<_AccuracyLabPage> createState() => _AccuracyLabPageState();
}

/// Visualizes the error introduced by approximating a continuous easing path.
///
/// The first strip is the production path: generated stops consumed by
/// Flutter's native shader. The second evaluates the curve and color-space mix
/// directly for every layout column. The third compares their visible,
/// premultiplied RGB output and amplifies the residual. These three renderers
/// must always share endpoints, curve, color space, and sample count.
class _AccuracyLabPageState extends State<_AccuracyLabPage> {
  var _curve = _curves[1];
  var _space = EasingColorSpace.oklab;
  var _samples = 15;
  var _amplification = 32;

  static const from = Color(0xFF4F46E5);
  static const to = Color(0x00F97316);

  @override
  Widget build(BuildContext context) {
    final generated = easeColorStops(
      colors: const [from, to],
      curve: _curve.curve,
      colorSpace: _space,
      samplesPerTransition: _samples,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Accuracy Lab', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'The bottom strip amplifies the mathematical difference. Black means the two renders match.',
        ),
        const SizedBox(height: 20),
        const Text('Native sampled gradient'),
        _Strip(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: EasingLinearGradient(
                colors: const [from, to],
                curve: _curve.curve,
                colorSpace: _space,
                samplesPerTransition: _samples,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Exact per-column CPU reference'),
        _Strip(
          child: CustomPaint(
            painter: _ExactPainter(
              from: from,
              to: to,
              curve: _curve.curve,
              space: _space,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Difference amplified ${_amplification}x'),
        _Strip(
          child: CustomPaint(
            painter: _DifferencePainter(
              from: from,
              to: to,
              curve: _curve.curve,
              space: _space,
              generated: generated,
              amplification: _amplification.toDouble(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Dropdown<_CurveOption>(
          label: 'Curve',
          value: _curve,
          values: _curves.where((c) => c.curve is! StepsCurve).toList(),
          display: (v) => v.name,
          onChanged: (v) => setState(() => _curve = v),
        ),
        const SizedBox(height: 12),
        _Dropdown<EasingColorSpace>(
          label: 'Color space',
          value: _space,
          values: EasingColorSpace.values,
          display: (v) => v.name,
          onChanged: (v) => setState(() => _space = v),
        ),
        const SizedBox(height: 12),
        Text('Extra stops: $_samples'),
        Slider(
          value: _samples.toDouble(),
          min: 1,
          max: 63,
          divisions: 62,
          onChanged: (v) => setState(() => _samples = v.round()),
        ),
        Text('Difference amplification: ${_amplification}x'),
        Slider(
          value: _amplification.toDouble(),
          min: 1,
          max: 128,
          divisions: 127,
          onChanged: (v) => setState(() => _amplification = v.round()),
        ),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68,
    child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
  );
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.display,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) display;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: [
      for (final item in values)
        DropdownMenuItem(value: item, child: Text(display(item))),
    ],
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

/// CPU reference for the continuous mathematical color path.
///
/// Each logical layout column evaluates `curve.transform(t)` and [mixColors]
/// directly. It does not interpolate between generated stops, so it is exact at
/// the displayed horizontal resolution, not an infinite-resolution oracle.
class _ExactPainter extends CustomPainter {
  const _ExactPainter({
    required this.from,
    required this.to,
    required this.curve,
    required this.space,
  });
  final Color from;
  final Color to;
  final Curve curve;
  final EasingColorSpace space;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.5;
    final columns = size.width.ceil();
    if (columns <= 0) return;
    for (var x = 0; x < columns; x++) {
      final t = columns == 1 ? 0.0 : x / (columns - 1);
      paint.color = mixColors(from, to, curve.transform(t), space);
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x.toDouble(), size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExactPainter old) =>
      from != old.from ||
      to != old.to ||
      curve != old.curve ||
      space != old.space;
}

/// Heat-map painter for sampled-versus-reference error.
///
/// It compares absolute premultiplied RGB channel differences, then multiplies
/// each residual by [amplification] and clips it for display. This is a native
/// visibility-oriented diagnostic, not a perceptual Delta-E color metric.
class _DifferencePainter extends CustomPainter {
  const _DifferencePainter({
    required this.from,
    required this.to,
    required this.curve,
    required this.space,
    required this.generated,
    required this.amplification,
  });
  final Color from;
  final Color to;
  final Curve curve;
  final EasingColorSpace space;
  final EasedColorStops generated;
  final double amplification;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.5;
    final columns = size.width.ceil();
    if (columns <= 0) return;
    for (var x = 0; x < columns; x++) {
      final t = columns == 1 ? 0.0 : x / (columns - 1);
      final exact = mixColors(from, to, curve.transform(t), space);
      final sampled = _sample(t);
      paint.color = Color.from(
        alpha: 1,
        red: ((exact.r * exact.a - sampled.r * sampled.a).abs() * amplification)
            .clamp(0, 1),
        green:
            ((exact.g * exact.a - sampled.g * sampled.a).abs() * amplification)
                .clamp(0, 1),
        blue:
            ((exact.b * exact.a - sampled.b * sampled.a).abs() * amplification)
                .clamp(0, 1),
      );
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x.toDouble(), size.height),
        paint,
      );
    }
  }

  /// Reproduces Flutter's straight-RGBA interpolation between generated stops.
  ///
  /// At a duplicated hard-stop coordinate, returning the later color models the
  /// right side of the discontinuity. The difference exists at one coordinate
  /// and does not turn the hard edge into a visible ramp.
  Color _sample(double t) {
    for (var i = 1; i < generated.stops.length; i++) {
      if (t <= generated.stops[i]) {
        final start = generated.stops[i - 1];
        final end = generated.stops[i];
        if (start == end) return generated.colors[i];
        return Color.lerp(
          generated.colors[i - 1],
          generated.colors[i],
          (t - start) / (end - start),
        )!;
      }
    }
    return generated.colors.last;
  }

  @override
  bool shouldRepaint(covariant _DifferencePainter old) =>
      curve != old.curve ||
      space != old.space ||
      generated != old.generated ||
      amplification != old.amplification;
}
