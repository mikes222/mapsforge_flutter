import 'dart:math';

import 'package:dart_common/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/util/rotate_helper.dart';

/// Recognizes scale gestures (zoom) and scales the map accordingly.
class ScaleGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  /// The absorption factor of a swipe. The lower the factor the faster swiping
  /// stops.
  final double swipeAbsorption;

  const ScaleGestureDetector({super.key, required this.mapModel, this.swipeAbsorption = 0.9}) : assert(swipeAbsorption >= 0 && swipeAbsorption <= 1);

  @override
  State<ScaleGestureDetector> createState() => _ScaleGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _ScaleGestureDetectorState extends State<ScaleGestureDetector> {
  static final _log = Logger('_ScaleGestureDetectorState');

  final bool doLog = true;

  _ScaleEvent? _eventHandler;

  // short click:
  // onTapDown
  // onTapUp
  //
  // long click:
  // onTapDown
  // onTapUp
  //
  // doubletap:
  // onDoubleTapDown
  // onTapDown
  // onDoubleTap
  //
  // normal drag event:
  // optionally (if the user waits a bit): onTapDown
  // onScaleStart with pointerCount 1
  // several onScaleUpdate with scale 1.0, rotation 0.0 and pointerCount: 1
  // onScaleEnd with velocity 0/0 and pointerCount: 0
  // NO onTapUp!
  //
  // zoom-in event:
  // optionally (if the user waits a bit): onTapDown
  // onScaleStart with pointerCount 2
  // several onScaleUpdate scale > 1, rotation normally != 0 and pointerCount: 2
  // onScaleEnd with velocity 0/0 and pointerCount: 1
  //
  // swipe: (similar to normal drag event)
  // optionally (if the user waits a bit): onTapDown
  // onScaleStart with pointerCount 1
  // several onScaleUpdate with scale 1.0, rotation 0.0 and pointerCount: 1
  // onScaleEnd with velocity -2324/-2699, pointerCount 0
  // velocity is in pixels per second
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onScaleStart: (ScaleStartDetails details) {
            if (doLog) _log.info("onScaleStart $details");
            if (details.pointerCount > 1) {
              _eventHandler = _ScaleEvent(
                mapModel: widget.mapModel,
                startLocalFocalPoint: details.localFocalPoint,
                startCenter: widget.mapModel.lastPosition!.getCenter(),
              );
            }
          },
          onScaleUpdate: (ScaleUpdateDetails details) {
            if (doLog) _log.info("onScaleUpdate $details");
            _eventHandler?.update(details: details);
          },
          onScaleEnd: (ScaleEndDetails details) {
            if (doLog) _log.info("onScaleEnd $details");
            _eventHandler?.end(details: details, size: constraints.biggest) ?? true;
            _eventHandler = null;
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/////////////////////////////////////////////////////////////////////////////

class _ScaleEvent {
  static final _log = Logger('FlutterGestureDetectorState._ScaleEvent');

  final MapModel mapModel;

  final Offset startLocalFocalPoint;

  final Mappoint startCenter;

  double? lastScale;

  Offset? lastFocalPoint;

  _ScaleEvent({required this.mapModel, required this.startLocalFocalPoint, required this.startCenter});

  void update({required ScaleUpdateDetails details}) {
    // do not send tiny changes
    if (lastScale != null &&
        ((details.scale / lastScale!) - 1).abs() < 0.01 &&
        lastFocalPoint != null &&
        (lastFocalPoint!.dx - details.focalPoint.dx).abs() < 5 &&
        (lastFocalPoint!.dy - details.focalPoint.dy).abs() < 5) {
      return;
    }
    // _log.info(
    //     "onScaleUpdate scale ${details.scale} around ${details.localFocalPoint}, rotation ${details.rotation}, size $size");
    lastScale = details.scale;
    lastFocalPoint = details.focalPoint;
    /*MapViewPosition? newPost =*/
    mapModel.scaleAround(details.localFocalPoint, details.scale);
    // Mappoint(details.localFocalPoint.dx * viewModel.viewScaleFactor,
    //     details.localFocalPoint.dy * viewModel.viewScaleFactor),
    // lastScale!);
  }

  bool end({required ScaleEndDetails details, required Size size}) {
    // no zoom: 0, double zoom: 1, half zoom: -1
    double zoomLevelOffset = log(lastScale!) / log(2);
    int zoomLevelDiff = zoomLevelOffset.round();
    if (zoomLevelDiff != 0) {
      // Complete large zooms towards gesture direction
      num mult = pow(2, zoomLevelDiff);
      // if (doLog)
      //   _log.info("onScaleEnd zooming now zoomLevelDiff $zoomLevelDiff");
      PositionInfo positionInfo = RotateHelper.normalize(mapModel.lastPosition!, size, startLocalFocalPoint.dx, startLocalFocalPoint.dy);
      mapModel.zoomToAround(
        positionInfo.latitude + (mapModel.lastPosition!.latitude! - positionInfo.latitude) / mult,
        positionInfo.longitude + (mapModel.lastPosition!.longitude! - positionInfo.longitude) / mult,
        mapModel.lastPosition!.zoomlevel + zoomLevelDiff,
      );
      //      if (doLog) _log.info("onScaleEnd  resulting in ${newPost.toString()}");
    } else if (lastScale != 1) {
      // no significant zoom. Restore the old zoom
      /*MapViewPosition newPost =*/
      mapModel.zoomTo(mapModel.lastPosition!.zoomlevel);
      // if (doLog)
      //   _log.info(
      //       "onScaleEnd Restored zoom to ${viewModel.mapViewPosition!.zoomLevel}");
    }
    return true;
  }
}
