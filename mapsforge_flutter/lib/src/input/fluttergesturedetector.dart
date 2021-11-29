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

  final Widget child;

  const FlutterGestureDetector(
      {Key? key, required this.viewModel, required this.child})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FlutterGestureDetectorState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class FlutterGestureDetectorState extends State<FlutterGestureDetector> {
  static final _log = new Logger('FlutterGestureDetectorState');

  Mappoint? _startLeftUpper;

  Offset? _startLocalFocalPoint;

  double? _lastScale;

  Offset? _doubleTapLocalPosition;

  @override
  Widget build(BuildContext context) {
    // short click:
    // onTapDown
    // onTapUp
    //
    // doubletap:
    // onDoubleTapDown
    // onDoubleTap
    //
    // normal drag event:
    // optionally (if the user waits a bit): onTapDown
    // onScaleStart with pointerCount 1
    // several onScaleUpdate with scale 1.0, rotation 0.0 and pointerCount: 1
    // onScaleEnd with velocity 0/0 and pointerCount: 0
    //
    // zoom-in event:
    // optionally (if the user waits a bit): onTapDown
    // onScaleStart with pointerCount 2
    // onScaleUpdate scale > 1, rotation normally != 0 and pointerCount: 2
    // onScaleEnd with velocity 0/0 and pointerCount: 1
    //
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails details) {
        // _log.info(
        //     "onTapDown $details with localPosition ${details.localPosition}");
      },
      onTapUp: (TapUpDetails details) {
//        _log.info("onTapUp $details");
        //if (positionRelative == null) return;
        //widget.mapModel.tapEvent(details.globalPosition.dx - positionRelative.dx, details.globalPosition.dy - positionRelative.dy);
        widget.viewModel
            .tapEvent(details.localPosition.dx, details.localPosition.dy);
        widget.viewModel.gestureEvent();
      },
      onDoubleTapDown: (TapDownDetails details) {
        // _log.info(
        //     "onDoubleTapDown $details with localPosition ${details.localPosition}");
        _doubleTapLocalPosition = details.localPosition;
      },
      onDoubleTap: () {
        // _log.info(
        //     "onDoubleTap with _doubleTapLocalPosition ${_doubleTapLocalPosition}");
        // it should always non-null but just for safety do a null-check
        if (_doubleTapLocalPosition == null) return;
        // lat/lon of the position where we double-clicked
        double latitude = widget.viewModel.mapViewPosition!.projection!
            .pixelYToLatitude(widget.viewModel.mapViewPosition!.leftUpper!.y +
                _doubleTapLocalPosition!.dy);
        double longitude = widget.viewModel.mapViewPosition!.projection!
            .pixelXToLongitude(widget.viewModel.mapViewPosition!.leftUpper!.x +
                _doubleTapLocalPosition!.dx);
        // interpolate the new center between the old center and where we pressed now. The new center is half-way between our double-pressed point and the old-center
        widget.viewModel.zoomInAround(
            (latitude - widget.viewModel.mapViewPosition!.latitude!) / 2 +
                widget.viewModel.mapViewPosition!.latitude!,
            (longitude - widget.viewModel.mapViewPosition!.longitude!) / 2 +
                widget.viewModel.mapViewPosition!.longitude!);
        widget.viewModel.gestureEvent();
      },
      onScaleStart: (ScaleStartDetails details) {
//        _log.info("onScaleStart $details");
        _startLocalFocalPoint = details.localFocalPoint;
        _startLeftUpper = widget.viewModel.mapViewPosition!.leftUpper;
        _lastScale = null;
        widget.viewModel.gestureEvent();
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
//        _log.info("onScaleUpdate $details");
        if (details.scale == 1) {
          // move around
          if (_startLeftUpper == null) return;
          // do not react if less than 5 points dragged
          if ((_startLocalFocalPoint!.dx - details.localFocalPoint.dx).abs() <
                  5 &&
              (_startLocalFocalPoint!.dy - details.localFocalPoint.dy).abs() <
                  5) return;
          widget.viewModel.setLeftUpper(
              _startLeftUpper!.x +
                  _startLocalFocalPoint!.dx -
                  details.localFocalPoint.dx,
              _startLeftUpper!.y +
                  _startLocalFocalPoint!.dy -
                  details.localFocalPoint.dy);
        } else {
          // zoom
          // do not send tiny changes
          if (_lastScale != null &&
              ((details.scale / _lastScale!) - 1).abs() < 0.01) return;
          // _log.info(
          //     "onScaleUpdate scale ${details.scale} around ${details.localFocalPoint}");
          _lastScale = details.scale;
          MapViewPosition? newPost = widget.viewModel.setScaleAround(
              Mappoint(details.localFocalPoint.dx, details.localFocalPoint.dy),
              _lastScale!);
        }
      },
      onScaleEnd: (ScaleEndDetails details) {
        //_log.info("onScaleEnd $details");
        // stop here if this was just a move-operation and NOT a scale-operation
        if (_lastScale == null) return;
        // no zoom: 0, double zoom: 1, half zoom: -1
        double zoomLevelOffset = log(this._lastScale!) / log(2);
        int zoomLevelDiff = zoomLevelOffset.round();
        // Complete large zooms towards gesture direction
        if (zoomLevelDiff != 0) {
          num mult = pow(2, zoomLevelDiff);
          //         _log.info("onScaleEnd zooming now zoomLevelDiff $zoomLevelDiff");
          // lat/lon of the position of the focus
          widget.viewModel.mapViewPosition!
              .calculateBoundingBox(widget.viewModel.viewDimension!);
          // lat/lon of the focalPoint
          double latitude = widget.viewModel.mapViewPosition!.projection!
              .pixelYToLatitude(widget.viewModel.mapViewPosition!.leftUpper!.y +
                  _startLocalFocalPoint!.dy);
          double longitude = widget.viewModel.mapViewPosition!.projection!
              .pixelXToLongitude(
                  widget.viewModel.mapViewPosition!.leftUpper!.x +
                      _startLocalFocalPoint!.dx);
          MapViewPosition newPost = widget.viewModel.zoomAround(
              latitude +
                  (widget.viewModel.mapViewPosition!.latitude! - latitude) /
                      mult,
              longitude +
                  (widget.viewModel.mapViewPosition!.longitude! - longitude) /
                      mult,
              widget.viewModel.mapViewPosition!.zoomLevel + zoomLevelDiff);
//          _log.info("onScaleEnd  resulting in ${newPost.toString()}");
        } else if (_lastScale != 1) {
          // no significant zoom. Restore the old zoom
          MapViewPosition newPost = widget.viewModel
              .setZoomLevel((widget.viewModel.mapViewPosition!.zoomLevel));
          // _log.info(
          //     "onScaleEnd Restored zoom to ${widget.viewModel.mapViewPosition!.zoomLevel}");
        }
      },
      child: widget.child,
    );
  }
}
