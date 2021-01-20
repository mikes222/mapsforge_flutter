import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

import '../../core.dart';

///
/// A detector for finger-gestures. It currently supports move, pinch-to-zoom and doubleclick
///
class FlutterGestureDetector extends StatefulWidget {
  final ViewModel viewModel;

  final MapViewPosition position;

  final Widget child;

  const FlutterGestureDetector({Key key, @required this.viewModel, this.position, @required this.child})
      : assert(viewModel != null),
        assert(child != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FlutterGestureDetectorState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class FlutterGestureDetectorState extends State<FlutterGestureDetector> {
  static final _log = new Logger('FlutterGestureDetectorState');

  Mappoint startLeftUpper;

  Offset startOffset;

  Offset _doubleTapOffset;

  double _lastScale;

  @override
  Widget build(BuildContext context) {
    //RenderBox positionRed = context.findRenderObject();
    //Offset positionRelative = positionRed?.localToGlobal(Offset.zero);
    //_log.info("positionRelative: ${positionRelative.toString()}");
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails details) {
        // for doubleTap
        _doubleTapOffset = details.localPosition;
      },
      onTapUp: (TapUpDetails details) {
        //_log.info(details.globalPosition.toString());
        //if (positionRelative == null) return;
        //widget.mapModel.tapEvent(details.globalPosition.dx - positionRelative.dx, details.globalPosition.dy - positionRelative.dy);
        widget.viewModel.tapEvent(details.localPosition.dx, details.localPosition.dy);
        widget.viewModel.gestureEvent();
      },
      onDoubleTap: () {
        if (_doubleTapOffset != null) {
          //if (positionRelative == null) return;
//          _log.info(" double tap at ${_doubleTapOffset.toString()}");
//          double xCenter = widget.mapModel.mapViewPosition.leftUpper.x
          BoundingBox boundingBox = widget.viewModel.mapViewPosition.calculateBoundingBox(widget.viewModel.viewDimension);
          // lat/lon of the position where we double-clicked
          double latitude = widget.viewModel.mapViewPosition.mercatorProjection
              .pixelYToLatitude(widget.viewModel.mapViewPosition.leftUpper.y + _doubleTapOffset.dy);
          double longitude = widget.viewModel.mapViewPosition.mercatorProjection
              .pixelXToLongitude(widget.viewModel.mapViewPosition.leftUpper.x + _doubleTapOffset.dx);
          // interpolate the new center between the old center and where we pressed now. The new center is half-way between our double-pressed point and the old-center

          widget.viewModel.zoomInAround(
              (latitude - widget.viewModel.mapViewPosition.latitude) / 2 + widget.viewModel.mapViewPosition.latitude,
              (longitude - widget.viewModel.mapViewPosition.longitude) / 2 + widget.viewModel.mapViewPosition.longitude);
        } else {
          widget.viewModel.zoomIn();
        }
        widget.viewModel.gestureEvent();
        _doubleTapOffset = null;
      },
      onScaleStart: (ScaleStartDetails details) {
        startOffset = details.focalPoint;
        startLeftUpper = widget.position?.leftUpper;
        _lastScale = null;
//        _log.info(details.toString());
        widget.viewModel.gestureEvent();
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        if (details.scale == 1) {
          // move around
          //_log.info(details.toString());
          if (startLeftUpper == null) return;
          // do not react if less than 5 points dragged
          if ((startOffset.dx - details.focalPoint.dx).abs() < 5 && (startOffset.dy - details.focalPoint.dy).abs() < 5) return;
          widget.viewModel.setLeftUpper(
              startLeftUpper.x + startOffset.dx - details.focalPoint.dx, startLeftUpper.y + startOffset.dy - details.focalPoint.dy);
        } else {
          // zoom
          // do not send tiny changes
          if (_lastScale != null && ((details.scale / _lastScale) - 1).abs() < 0.01) return;
          // _log.info(
          //     "GestureDetector scale ${details.scale} around ${details.focalPoint.toString()} or ${details.localFocalPoint.toString()}");
          _lastScale = details.scale;
          MapViewPosition newPost = widget.viewModel.setScale(Mappoint(details.localFocalPoint.dx, details.localFocalPoint.dy), _lastScale);
        }
      },
      onScaleEnd: (ScaleEndDetails details) {
        //_log.info(details.toString());
        if (_lastScale == null) return;
        // no zoom: 0, double zoom: 1, half zoom: -1
        double zoomLevelOffset = log(this._lastScale) / log(2);
        if (zoomLevelOffset.abs() >= 0.5) {
          // Complete large zooms towards gesture direction
//            zoomLevelDiff = (zoomLevelOffset < 0 ? zoomLevelOffset.floor() : zoomLevelOffset.ceil()).round();
          int zoomLevelDiff = zoomLevelOffset.round();
          if (zoomLevelDiff != 0) {
            //_log.info("zooming now at $zoomLevelDiff for ${widget.position.toString()}");
            MapViewPosition newPost = widget.viewModel.setZoomLevel(widget.position.zoomLevel + zoomLevelDiff);
            //_log.info(
            //    "  resulting in ${newPost.toString()} or ${newPost.mercatorProjection} or ${newPost.calculateBoundingBox(widget.viewModel.viewDimension)}}");
          }
        } else if (_lastScale != 1) {
          // no significant zoom. Restore the old zoom
          MapViewPosition newPost = widget.viewModel.setZoomLevel((widget.position.zoomLevel));
          //_log.info("Restored zoom to ${widget.position.zoomLevel}");
        }
      },
      child: widget.child,
    );
  }
}
