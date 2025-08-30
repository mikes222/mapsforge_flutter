import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/util/rotate_helper.dart';

/// Two‐finger rotation overlay that never blocks pan/zoom,
/// and uses ViewModel.rotateDelta() to apply each twist incrementally.
class ScaleGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  /// degrees of twist before we start rotating
  final double thresholdDeg;

  const ScaleGestureDetector({super.key, required this.mapModel, this.thresholdDeg = 10.0});

  @override
  State<ScaleGestureDetector> createState() => _ScaleGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _ScaleGestureDetectorState extends State<ScaleGestureDetector> {
  static final _log = Logger('_Scale2GestureDetectorState');

  final bool doLog = false;

  _Handler? _handler;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (doLog) _log.info("onPointerDown $event ${event.pointer}");
            _handler ??= _Handler(size: constraints.biggest, lastPosition: widget.mapModel.lastPosition!, mapModel: widget.mapModel);
            _handler!._addOffset(event.pointer, event.position);
          },
          onPointerMove: (event) {
            if (doLog) _log.info("onPointerMove $event ${event.pointer}");
            _handler?._movePointer(event.pointer, event.position);
          },
          onPointerUp: (event) {
            if (doLog) _log.info("onPointerUp $event ${event.pointer}");
            bool cancel = _handler?._removeOffset(event.pointer) ?? false;
            if (cancel) _handler = null;
          },
          onPointerCancel: (event) {
            if (doLog) _log.info("onPointerCancel $event ${event.pointer}");
            _handler?._cancel();
            _handler = null;
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Handler {
  final MapPosition lastPosition;

  final MapModel mapModel;

  final Size size;

  final Map<int, Offset> _points = {};

  _Vector? _startVector;

  _Vector? _lastVector;

  double _lastScale = 1;

  _Handler({required this.lastPosition, required this.mapModel, required this.size});

  void _addOffset(int id, Offset offset) {
    _points[id] = offset;
    if (_points.length != 2) {
      return;
    }
    _startVector = _Vector(_points.values.first, _points.values.last);
  }

  bool _removeOffset(int id) {
    _points.remove(id);
    if (_points.length == 1) {
      if (_startVector != null) _sendEnd();
    }
    if (_points.isEmpty) return true;
    return false;
  }

  void _cancel() {
    _points.clear();
    if (_startVector != null) _sendEnd();
  }

  void _movePointer(int id, Offset offset) {
    if (!_points.containsKey(id)) {
      return;
    }
    _points[id] = offset;
    if (_points.length != 2) {
      return;
    }
    _Vector newVector = _Vector(_points.values.first, _points.values.last);
    if (newVector.getLength().isNaN) return;
    // if (_lastVector != null &&
    //     (newVector.getLength() / _lastVector!.getLength() - 1).abs() < 0.01 &&
    //     (newVector.getFocalPoint().dx - _lastVector!.getFocalPoint().dx).abs() < 5 &&
    //     (newVector.getFocalPoint().dy - _lastVector!.getFocalPoint().dy).abs() < 5) {
    //   // do not send tiny changes
    //   return;
    // }
    _lastScale = newVector.getLength() / _startVector!.getLength();
    mapModel.scaleAround(newVector.getFocalPoint(), _lastScale);
    _lastVector = newVector;
  }

  void _sendEnd() {
    // no zoom: 0, double zoom: 1, half zoom: -1
    double zoomLevelOffset = log(_lastScale) / log(2);
    int zoomLevelDiff = zoomLevelOffset.round();
    if (zoomLevelDiff != 0) {
      // Complete large zooms towards gesture direction
      num mult = pow(2, zoomLevelDiff);
      // if (doLog)
      //   _log.info("onScaleEnd zooming now zoomLevelDiff $zoomLevelDiff");
      PositionInfo positionInfo = RotateHelper.normalize(lastPosition, size, _lastVector!.getFocalPoint().dx, _lastVector!.getFocalPoint().dy);
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
