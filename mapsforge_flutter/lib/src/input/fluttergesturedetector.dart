import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import '../../core.dart';

class FlutterGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  final MapViewPosition position;

  final Widget child;

  const FlutterGestureDetector({Key key, @required this.mapModel, this.position, @required this.child})
      : assert(mapModel != null),
        assert(child != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FlutterGestureDetectorState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class FlutterGestureDetectorState extends State<FlutterGestureDetector> {
  Mappoint startLeftUpper;

  Offset startOffset;

  double _lastScale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (TapUpDetails details) {
        //print(details.globalPosition.toString());
        widget.mapModel.tapEvent(details.globalPosition.dx, details.globalPosition.dy);
      },
      onDoubleTap: () {
        widget.mapModel.zoomIn();
      },
      onScaleStart: (ScaleStartDetails details) {
        startOffset = details.focalPoint;
        startLeftUpper = widget.position?.leftUpper;
        _lastScale = null;
        print(details.toString());
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        if (details.scale == 1) {
          if (startLeftUpper == null) return;
          widget.mapModel.setLeftUpper(
              startLeftUpper.x + startOffset.dx - details.focalPoint.dx, startLeftUpper.y + startOffset.dy - details.focalPoint.dy);
        } else {
          print(details.toString());
          _lastScale = details.scale;
        }
      },
      onScaleEnd: (ScaleEndDetails details) {
        print(details.toString());
        if (_lastScale == null) return;
        // no zoom: 0, double zoom: 1, half zoom: -1
        double zoomLevelOffset = log(this._lastScale) / log(2);
        int zoomLevelDiff;
        if (zoomLevelOffset.abs() >= 0.5) {
          // Complete large zooms towards gesture direction
//            zoomLevelDiff = (zoomLevelOffset < 0 ? zoomLevelOffset.floor() : zoomLevelOffset.ceil()).round();
          zoomLevelDiff = zoomLevelOffset.round();
        } else {}
        if (zoomLevelDiff != 0) widget.mapModel.setZoomLevel((widget.position?.zoomLevel ?? widget.mapModel.DEFAULT_ZOOM) + zoomLevelDiff);
      },
      child: widget.child,
    );
  }
}
