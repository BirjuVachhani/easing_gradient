import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Example-only analytic alpha mask, not a replacement for gradient color mixing.
///
/// Uses one layer for both edges. Compare with dither zero to isolate noise from
/// the analytic curve and the existing recipe's two-layer composition.
class AnalyticAlphaFade extends StatefulWidget {
  const AnalyticAlphaFade({
    super.key,
    required this.child,
    required this.curve,
    required this.extent,
    this.dither = 0,
  });

  final Widget child;
  final Cubic curve;
  final double extent;

  /// Peak-to-peak alpha noise measured in 1/255 units. Zero disables noise.
  final double dither;

  @override
  State<AnalyticAlphaFade> createState() => _AnalyticAlphaFadeState();
}

class _AnalyticAlphaFadeState extends State<AnalyticAlphaFade> {
  static Future<ui.FragmentProgram>? _program;
  ui.FragmentShader? _shader;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await (_program ??= ui.FragmentProgram.fromAsset(
        'shaders/alpha_fade.frag',
      ));
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Diagnostic shader unavailable: $_error'));
    }
    final shader = _shader;
    if (shader == null) return const Center(child: CircularProgressIndicator());
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final curve = widget.curve;
        shader
          ..setFloat(0, bounds.width)
          ..setFloat(1, bounds.height)
          ..setFloat(2, dpr)
          ..setFloat(3, widget.extent.clamp(0.0, 0.5))
          ..setFloat(4, curve.a)
          ..setFloat(5, curve.b)
          ..setFloat(6, curve.c)
          ..setFloat(7, curve.d)
          ..setFloat(8, widget.dither);
        return shader;
      },
      child: widget.child,
    );
  }
}
