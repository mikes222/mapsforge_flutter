import 'dart:math';
import 'dart:ui';

import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/gesture/default_handler.dart';
import 'package:mapsforge_flutter/src/util/rotate_helper.dart';

class ScaleHandler extends DefaultHandler {
  bool _active = false;

  _Vector? _startVector;

  _Vector? _lastVector;

  double _lastScale = 1;

  ScaleHandler({required super.longPressDuration, required super.mapModel});

  @override
  void cancelTimer() {
    super.cancelTimer();
    _active = false;
    _startVector = null;
    _lastVector = null;
    _lastScale = 1;
  }

  @override
  void onPointerDown(MapPosition position, int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (pointers.length != 2) {
      cancelTimer();
      return;
    }
    //super.onPointerDown(position, pointerId, offset, pointers);
    startPosition = position;
    startOffset = offset;
    _startVector = _Vector(pointers.values.first, pointers.values.last);
    _active = true;
  }

  @override
  void onPointerUp(int pointerId, Offset offset, Map<int, Offset> pointers) {
    super.onPointerUp(pointerId, offset, pointers);
    // no zoom: 0, double zoom: 1, half zoom: -1
    double zoomLevelOffset = log(_lastScale) / log(2);
    int zoomLevelDiff = zoomLevelOffset.round();
    if (zoomLevelDiff != 0) {
      // Complete large zooms towards gesture direction
      num mult = pow(2, zoomLevelDiff);
      // if (doLog)
      //   _log.info("onScaleEnd zooming now zoomLevelDiff $zoomLevelDiff");
      PositionInfo positionInfo = RotateHelper.normalize(startPosition!, size, _lastVector!.getFocalPoint().dx, _lastVector!.getFocalPoint().dy);
      mapModel.zoomToAround(
        positionInfo.latitude + (mapModel.lastPosition!.latitude - positionInfo.latitude) / mult,
        positionInfo.longitude + (mapModel.lastPosition!.longitude - positionInfo.longitude) / mult,
        mapModel.lastPosition!.zoomlevel + zoomLevelDiff,
      );
      //      if (doLog) _log.info("onScaleEnd  resulting in ${newPost.toString()}");
    } else if (_lastScale != 1) {
      // no significant zoom. Restore the old zoom
      /*MapViewPosition newPost =*/
      mapModel.zoomTo(mapModel.lastPosition!.zoomlevel);
      // if (doLog)
      //   _log.info(
      //       "onScaleEnd Restored zoom to ${viewModel.mapViewPosition!.zoomLevel}");
    }
    cancelTimer();
  }

  @override
  void onPointerMove(int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (!_active) return;
    super.onPointerMove(pointerId, offset, pointers);
    _Vector newVector = _Vector(pointers.values.first, pointers.values.last);
    if (newVector.getLength().isNaN) return;
    _lastScale = newVector.getLength() / _startVector!.getLength();
    mapModel.scaleAround(newVector.getFocalPoint(), _lastScale);
    _lastVector = newVector;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Vector {
  final Offset start;

  final Offset end;

  double? _length;

  Offset? _focalPoint;

  _Vector(this.start, this.end);

  double getLength() {
    if (_length != null) return _length!;
    _length = sqrt((end.dx - start.dx) * (end.dx - start.dx) + (end.dy - start.dy) * (end.dy - start.dy));
    return _length!;
  }

  Offset getFocalPoint() {
    if (_focalPoint != null) return _focalPoint!;
    _focalPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    return _focalPoint!;
  }

  @override
  String toString() {
    return '_Vector{_length: $_length, _focalPoint: $_focalPoint}';
  }
}
