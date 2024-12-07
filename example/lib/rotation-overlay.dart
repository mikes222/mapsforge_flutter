import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';

/// A very simple slider on top of the map to rotate the map. This is used to demonstrate
/// the map-rotation feature. In your case you would maybe call viewModel.rotate() with the
/// bearing from the GPS receiver instead.
class RotationOverlay extends StatefulWidget {

  final ViewModel viewModel;

  RotationOverlay(this.viewModel);
  
  @override
  State<StatefulWidget> createState() {
    return _RotationState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _RotationState extends State {

  double _rotation = 0;

  @override
  RotationOverlay get widget => super.widget as RotationOverlay;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 100,
      right: 100,
      child: Slider(
        value: _rotation,
        min: 0,
        max: 359,
        onChanged: (double value) {
          _rotation = value;
          widget.viewModel.rotate(_rotation);
          setState(() {

          });
        },
      ),
    );
  }
}
