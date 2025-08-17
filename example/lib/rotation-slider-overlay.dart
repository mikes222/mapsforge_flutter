import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';

/// A very simple slider on top of the map to rotate the map. This is used to demonstrate
/// the map-rotation feature. In your case you would maybe call viewModel.rotate() with the
/// bearing from the GPS receiver instead. See also RotationOverlay.
class RotationSliderOverlay extends StatefulWidget {
  final ViewModel viewModel;

  const RotationSliderOverlay(this.viewModel);

  @override
  State<StatefulWidget> createState() {
    return _RotationSliderState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _RotationSliderState extends State {
  double _rotation = 0;

  @override
  RotationSliderOverlay get widget => super.widget as RotationSliderOverlay;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 100,
      right: 100,
      child: StreamBuilder(
          stream: widget.viewModel.observePosition,
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.hasData) {
              _rotation = asyncSnapshot.data!.rotation;
            }
            return Slider(
              value: _rotation,
              min: 0,
              max: 360,
              onChanged: (double value) {
                _rotation = value;
                widget.viewModel.rotate(Projection.normalizeRotation(_rotation));
                setState(() {});
              },
            );
          }),
    );
  }
}
