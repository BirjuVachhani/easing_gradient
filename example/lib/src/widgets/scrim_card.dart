import 'package:flutter/material.dart';

/// The example's stand-in photograph.
///
/// A real photo rather than a synthetic gradient, because a scrim laid over a
/// smooth ramp has nothing to give its seam away. Sky gives the fade an even
/// tone to band against and the architecture gives it detail to sit over.
/// Credits and license are in `assets/images/CREDITS.md`.
class PhotoBackdrop extends StatelessWidget {
  const PhotoBackdrop({super.key, this.alignment = Alignment.center});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/osaka.webp',
    fit: BoxFit.cover,
    alignment: alignment,
  );
}

/// A photo card whose bottom scrim is supplied by the caller.
///
/// The caption is real editorial text rather than a label, because the whole
/// question a scrim answers is whether small type stays readable without a
/// visible band cutting across the image.
class ScrimCard extends StatelessWidget {
  const ScrimCard({
    super.key,
    required this.scrim,
    this.scrimHeight = 0.62,
    this.compact = false,
  });

  /// The overlay that darkens the lower part of the card. Callers pass a native
  /// and an eased gradient to compare the two.
  final Gradient scrim;

  /// Fraction of the card height the scrim covers.
  final double scrimHeight;

  /// Tightens type and padding for small preview tiles.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double pad = compact ? 16 : 24;
    return Stack(
      fit: StackFit.expand,
      children: [
        const PhotoBackdrop(alignment: Alignment.topCenter),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: scrimHeight,
            child: DecoratedBox(decoration: BoxDecoration(gradient: scrim)),
          ),
        ),
        Positioned(
          left: pad,
          right: pad,
          bottom: compact ? 14 : 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '48 HOURS IN',
                style: TextStyle(
                  color: const Color(0xFFFFD9A8),
                  fontSize: compact ? 9.5 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                'Osaka',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Georgia',
                  fontFamilyFallback: const ['Times New Roman', 'serif'],
                  fontSize: compact ? 24 : 34,
                  height: 1.1,
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
              Text(
                'Neon nights, quiet shrines, and the best thing you have ever '
                'eaten at 2am.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: compact ? 12 : 14.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
