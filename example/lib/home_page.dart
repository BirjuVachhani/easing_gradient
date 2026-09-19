import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'src/docs/docs_content.dart' show DocCode;
import 'src/theme/tokens.dart';
import 'src/widgets/app_shell.dart';
import 'src/widgets/easing_showcase.dart';
import 'src/widgets/section.dart';

/// Landing page.
///
/// The order is deliberate: show the problem in a real card before describing
/// it, then name the three failures behind it, then the fix, then why the fix
/// costs nothing at paint time.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Hero(),
            const _RealWorld(),
            const _Problem(),
            const _Solution(),
            const _WhyBetter(),
            const _ClosingCta(),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final compact = context.isCompact;
    final headlineSize = compact ? 42.0 : 66.0;
    return Padding(
      padding: EdgeInsets.only(
        top: AppLayout.navHeight + (compact ? 56 : 92),
        bottom: compact ? 44 : 68,
      ),
      child: ContentContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBadge('Flutter package  ·  v0.2.0', mono: true),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Text(
                'Take the hard edge\nout of your gradients.',
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: headlineSize,
                  fontWeight: FontWeight.w600,
                  height: 1.03,
                  letterSpacing: headlineSize * -0.026,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'Flutter’s LinearGradient moves at one speed the whole way, so '
                'wherever it stops you see a faint line. Give it a Curve '
                'instead and the line goes.',
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: compact ? 17 : 20,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InstallCommand(command: 'flutter pub add easing_gradient'),
                _ActionButton(
                  label: 'Read the docs',
                  icon: Icons.menu_book_outlined,
                  filled: true,
                  onTap: () => context.go(SitePage.docs.path),
                ),
                _ActionButton(
                  label: 'Browse examples',
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => context.go(SitePage.examples.path),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The lead: one production-shaped card, built twice, differing only in the
/// gradient class that makes its caption readable.
class _RealWorld extends StatelessWidget {
  const _RealWorld();

  @override
  Widget build(BuildContext context) {
    return Section(
      background: context.colors.surface,
      border: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading(
            title: 'The same card, one class name apart',
            subtitle:
                'Both cards fade one photo out behind its caption, between '
                'stops at 15% and 75%. The only difference is the shape of '
                'the ramp in between. Drag the slider to bend the right one '
                'and watch the band across the sky go.',
          ),
          const SizedBox(height: 32),
          const EasingShowcase(),
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerLeft,
            child: _TextLink(
              label: 'See all eighteen comparisons',
              onTap: () => context.go(SitePage.compare.path),
            ),
          ),
        ],
      ),
    );
  }
}

/// Names the three separate failures a native gradient runs into, each with the
/// smallest strip that makes it visible.
class _Problem extends StatelessWidget {
  const _Problem();

  @override
  Widget build(BuildContext context) {
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading(
            title: 'Where gradients usually go wrong',
            subtitle:
                'The seam is the one people notice. There are two quieter '
                'problems sitting underneath it: the route a gradient takes '
                'between two colors, and what happens to a color on its way '
                'to transparent.',
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 18.0;
              final columns = constraints.maxWidth >= 900 ? 3 : 1;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: width,
                    child: _ProblemCard(
                      title: 'The seam',
                      body:
                          'Something changing at a constant rate has to stop '
                          'somewhere, and the stop shows up as a crease. '
                          'It’s most obvious in the scrim behind a caption.',
                      backdrop: const Color(0xFFE08A3C),
                      nativeDetail: 'Constant rate, hard stop',
                      easedDetail: 'Curves.easeInOut',
                      native: const LinearGradient(
                        colors: [Colors.transparent, Color(0xFF000000)],
                      ),
                      // Same colors, same sRGB path; only the ramp is shaped.
                      eased: EasingLinearGradient(
                        colors: const [Colors.transparent, Color(0xFF000000)],
                        colorSpace: EasingColorSpace.srgb,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _ProblemCard(
                      title: 'The muddy middle',
                      body:
                          'Mixing two saturated colors in straight RGB drags '
                          'the midpoint through something duller than either '
                          'end. OKLab keeps the middle as bright as the colors '
                          'on both sides of it.',
                      nativeDetail: 'Straight RGB',
                      easedDetail: 'EasingColorSpace.oklab',
                      native: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFFFACC15)],
                      ),
                      // Linear pacing on both sides, so only the space differs.
                      eased: EasingLinearGradient(
                        colors: const [Color(0xFF1D4ED8), Color(0xFFFACC15)],
                        curve: Curves.linear,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _ProblemCard(
                      title: 'The gray ghost',
                      body:
                          'Colors.transparent is transparent black, so fading '
                          'to it pulls every color toward gray on the way out. '
                          'Premultiplying drops the alpha and leaves the hue '
                          'where it was.',
                      backdrop: const Color(0xFFF4F4F5),
                      nativeDetail: 'Color drifts to gray',
                      easedDetail: 'Premultiplied alpha',
                      native: const LinearGradient(
                        colors: [Color(0xFFE11D48), Color(0x00000000)],
                      ),
                      eased: EasingLinearGradient(
                        colors: const [Color(0xFFE11D48), Color(0x00000000)],
                        curve: Curves.linear,
                        colorSpace: EasingColorSpace.srgb,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.title,
    required this.body,
    required this.native,
    required this.eased,
    required this.nativeDetail,
    required this.easedDetail,
    this.backdrop,
  });

  final String title;
  final String body;
  final Gradient native;
  final Gradient eased;
  final String nativeDetail;
  final String easedDetail;

  /// Painted under both strips, for gradients that only read against a
  /// particular background.
  final Color? backdrop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          _ProblemStrip(
            good: false,
            gradient: native,
            detail: nativeDetail,
            backdrop: backdrop,
          ),
          const SizedBox(height: 10),
          _ProblemStrip(
            good: true,
            gradient: eased,
            detail: easedDetail,
            backdrop: backdrop,
          ),
        ],
      ),
    );
  }
}

class _ProblemStrip extends StatelessWidget {
  const _ProblemStrip({
    required this.good,
    required this.gradient,
    required this.detail,
    this.backdrop,
  });

  final bool good;
  final Gradient gradient;
  final String detail;
  final Color? backdrop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color mark = good ? colors.accent : const Color(0xFFEF6068);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          good ? Icons.check_rounded : Icons.close_rounded,
          size: 15,
          color: mark,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: SizedBox(
                  height: 34,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (backdrop != null) ColoredBox(color: backdrop!),
                      DecoratedBox(
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                detail,
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontFamily: AppFonts.mono,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// How the package fixes all three without changing how anything paints.
class _Solution extends StatelessWidget {
  const _Solution();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Section(
      background: colors.surface,
      border: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading(
            title: 'Swap the class name, keep everything else',
            subtitle:
                'EasingLinearGradient, EasingRadialGradient and '
                'EasingSweepGradient extend the gradients you’re already '
                'using, so the widget around them doesn’t change.',
          ),
          const SizedBox(height: 26),
          const DocCode(_swapSnippet),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.readingMaxWidth,
            ),
            child: Text(
              'Building one samples the curve and mixes each neighboring pair '
              'of colors in whichever space you asked for, then writes the '
              'result out as a plain list of colors and stops. After that '
              'it’s a normal Flutter gradient going through the normal '
              'shader, with no extra work happening per frame.',
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 15.5,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const String _swapSnippet = '''
// Before
LinearGradient(
  colors: [Colors.transparent, Colors.black],
)

// After: same geometry, same paint path
EasingLinearGradient(
  colors: [Colors.transparent, Colors.black],
  curve: Curves.easeInOut,            // any Curve, including your own
  colorSpace: EasingColorSpace.oklab, // or oklch, linearRgb, srgb, hsl
)''';

class _WhyBetter extends StatelessWidget {
  const _WhyBetter();

  static const items = [
    (
      icon: Icons.speed_rounded,
      title: 'No shader to maintain',
      body:
          'A fragment shader will draw you a perfect ramp, but then you own an '
          'asset and a pipeline and you pay for it on every frame. This does '
          'its arithmetic in the constructor and leaves the painting alone.',
    ),
    (
      icon: Icons.tune_rounded,
      title: 'Any Curve, per transition',
      body:
          'Stops you place by hand are an approximation of a curve you already '
          'had in mind. Pass the Curve and skip the arithmetic, or give every '
          'pair of colors its own. StepsCurve gets you exact hard bands.',
    ),
    (
      icon: Icons.color_lens_outlined,
      title: 'Five color spaces',
      body:
          'OKLab, OKLCH, linear RGB, sRGB and HSL, all with premultiplied '
          'alpha. Wide-gamut output is something you ask for through '
          'outputColorSpace; it never happens behind your back.',
    ),
    (
      icon: Icons.swap_horiz_rounded,
      title: 'A drop-in subclass',
      body:
          'Everything passes through: begin, end, center, radius, focal '
          'points, angles, stops, transforms, tile modes. Anywhere a Gradient '
          'works, these work.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading(
            title: 'Why not just hand-place the stops',
            subtitle:
                'You can, and for a single gradient it’s probably the right '
                'call. It gets tedious once the curve or the palette or the '
                'color space changes and every list you tuned by hand has to '
                'be worked out again.',
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 18.0;
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(item.icon, size: 20, color: colors.foreground),
                            const SizedBox(height: 18),
                            Text(
                              item.title,
                              style: TextStyle(
                                color: colors.foreground,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.body,
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClosingCta extends StatelessWidget {
  const _ClosingCta();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Section(
      border: true,
      background: colors.surfaceInset,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start by changing one class name.',
                  style: TextStyle(
                    color: colors.foreground,
                    fontSize: context.isCompact ? 24 : 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Curves, color spaces, custom stops and hard bands are all '
                  'there when a design needs them, and ignorable until it '
                  'does.',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          if (!context.isCompact) ...[
            const SizedBox(width: 32),
            _ActionButton(
              label: 'Documentation',
              icon: Icons.arrow_forward_rounded,
              filled: true,
              onTap: () => context.go(SitePage.docs.path),
            ),
          ],
        ],
      ),
    );
  }
}

class _InstallCommand extends StatefulWidget {
  const _InstallCommand({required this.command});

  final String command;

  @override
  State<_InstallCommand> createState() => _InstallCommandState();
}

class _InstallCommandState extends State<_InstallCommand> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.command));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SelectionContainer.disabled(
      child: Container(
        height: 46,
        padding: const EdgeInsets.only(left: 18, right: 7),
        decoration: BoxDecoration(
          color: dark ? Colors.black : const Color(0xFF171717),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: dark
              ? Border.all(color: Colors.white.withValues(alpha: 0.18))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flexible so a phone-width viewport ellipsizes the command
            // instead of overflowing the pill.
            Flexible(
              child: Text(
                widget.command,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 14,
                  letterSpacing: -0.2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _copy,
              tooltip: _copied ? 'Copied' : 'Copy install command',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 16,
                color: _copied ? const Color(0xFF34D399) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18),
        ),
        backgroundColor: WidgetStatePropertyAll(
          filled ? colors.primary : colors.surface,
        ),
        foregroundColor: WidgetStatePropertyAll(
          filled ? colors.onPrimary : colors.foreground,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
    );
    return SelectionContainer.disabled(child: button);
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SelectionContainer.disabled(
    child: TextButton.icon(
      onPressed: onTap,
      label: Text(label),
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      iconAlignment: IconAlignment.end,
      style: TextButton.styleFrom(
        foregroundColor: context.colors.foreground,
        padding: EdgeInsets.zero,
      ),
    ),
  );
}
