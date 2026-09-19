import 'package:device_preview/device_preview.dart';
import 'package:device_preview/presets.dart';
import 'package:flutter/material.dart';

/// An iPhone 17 Pro body around a normal widget subtree.
///
/// device_preview 3 exposes its frame as a render object that expects to be
/// exactly the simulated screen size and paints the phone body outside those
/// bounds. This wrapper reserves the full body rectangle, scales it to [height],
/// then offsets the screen back to the frame's origin.
class IPhone17ProFrame extends StatefulWidget {
  const IPhone17ProFrame({
    super.key,
    required this.child,
    this.height = 690,
    this.brightness = Brightness.dark,
  });

  final Widget child;
  final double height;
  final Brightness brightness;

  @override
  State<IPhone17ProFrame> createState() => _IPhone17ProFrameState();
}

class _IPhone17ProFrameState extends State<IPhone17ProFrame> {
  static const preset = DevicePresets.iPhone17Pro;
  late final ValueNotifier<DeviceSimulation?> _simulation = ValueNotifier(
    _resolvedSimulation(),
  );

  DeviceSimulation _resolvedSimulation() => preset.resolve().copyWith(
    platformBrightness: widget.brightness,
    touchInput: false,
  );

  @override
  void didUpdateWidget(IPhone17ProFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.brightness != oldWidget.brightness) {
      _simulation.value = _resolvedSimulation();
    }
  }

  @override
  void dispose() {
    _simulation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simulation = _simulation.value!;
    final frame = simulation.frame!;
    final bodySize = frame.size;
    final scale = widget.height / bodySize.height;
    final screenSize = simulation.screenSize!;
    final screenOffset = frame.screenOffset;

    return SizedBox(
      width: bodySize.width * scale,
      height: bodySize.height * scale,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: screenOffset,
            child: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: DevicePreviewFrame(
                simulation: _simulation,
                child: MediaQuery(
                  data: MediaQueryData(
                    size: screenSize,
                    devicePixelRatio: simulation.devicePixelRatio ?? 3,
                    padding: simulation.padding ?? EdgeInsets.zero,
                    viewPadding: simulation.viewPadding ?? EdgeInsets.zero,
                    systemGestureInsets:
                        simulation.systemGestureInsets ?? EdgeInsets.zero,
                    platformBrightness: widget.brightness,
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      color: Colors.white,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
