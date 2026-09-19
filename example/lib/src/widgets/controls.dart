import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A labelled dropdown: a small caption above a bordered select.
///
/// Material's floating-label field is built for forms on a phone; a caption over
/// a compact control reads correctly in a settings column on the web.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
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
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ControlLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: colors.mutedForeground,
          ),
          dropdownColor: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          style: TextStyle(
            color: colors.foreground,
            fontFamily: AppFonts.sans,
            fontSize: 14,
          ),
          items: [
            for (final item in values)
              DropdownMenuItem(value: item, child: Text(display(item))),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ],
    );
  }
}

/// A labelled slider with its current value shown on the right of the caption.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.valueLabel,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: _ControlLabel(label)),
            const SizedBox(width: 10),
            Text(
              valueLabel ?? value.round().toString(),
              style: TextStyle(
                color: colors.foreground,
                fontFamily: AppFonts.mono,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A switch row: label and supporting line on the left, switch on the right.
class LabeledSwitch extends StatelessWidget {
  const LabeledSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: colors.mutedForeground,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bordered panel that groups related controls in a settings column.
class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// A caption above a control.
class _ControlLabel extends StatelessWidget {
  const _ControlLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: context.colors.mutedForeground,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
  );
}

/// Places a demo beside its controls on wide viewports and stacks them when
/// narrow, so a settings column never squeezes the preview on a phone.
class DemoLayout extends StatelessWidget {
  const DemoLayout({
    super.key,
    required this.preview,
    required this.controls,
    this.controlsWidth = 320,
  });

  final Widget preview;
  final Widget controls;
  final double controlsWidth;

  @override
  Widget build(BuildContext context) {
    if (context.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [preview, const SizedBox(height: 20), controls],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: preview),
        const SizedBox(width: 28),
        SizedBox(width: controlsWidth, child: controls),
      ],
    );
  }
}
