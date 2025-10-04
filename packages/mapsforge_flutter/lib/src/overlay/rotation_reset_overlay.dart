import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';

class RotationResetOverlay extends StatefulWidget {
  final MapModel mapModel;

  /// degrees of twist before we start rotating
  final double thresholdDeg;

  const RotationResetOverlay({super.key, required this.mapModel, this.thresholdDeg = 5});

  @override
  State<RotationResetOverlay> createState() => _RotationResetOverlayState();
}

//////////////////////////////////////////////////////////////////////////////

class _RotationResetOverlayState extends State<RotationResetOverlay> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.mapModel.positionStream,
      builder: (context, AsyncSnapshot<MapPosition?> snapshot) {
        if ((snapshot.data?.rotation.abs() ?? 0) < widget.thresholdDeg) return const SizedBox();
        return Positioned(right: 20, top: 20, child: _buildButton());
      },
    );
  }

  Widget _buildButton() {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final fillColor = Theme.of(context).buttonTheme.colorScheme?.surface ?? (brightness == Brightness.light ? Colors.white : Colors.black);

    return RawMaterialButton(
      onPressed: () => widget.mapModel.rotateTo(0),
      elevation: 2.0,
      fillColor: fillColor,
      child: const Icon(Icons.screen_lock_rotation),
      padding: const EdgeInsets.all(10.0),
      shape: const CircleBorder(),
      constraints: const BoxConstraints(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
