import 'dart:math';
import 'dart:ui';

import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/gesture/default_handler.dart';

class RotationHandler extends DefaultHandler {
  /// degrees of twist before we start rotating
  final double thresholdDeg;

  final int pointerCount;

  bool _active = false;

  bool _rotating = false;

  double? _baselineAngle;

  RotationHandler({required super.longPressDuration, required super.mapModel, this.thresholdDeg = 5.0, this.pointerCount = 3});

  @override
  void cancelTimer() {
    super.cancelTimer();
    _active = false;
    _rotating = false;
    _baselineAngle = null;
  }

  @override
  void onPointerDown(MapPosition position, int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (pointers.length != pointerCount) {
      cancelTimer();
      return;
    }
    //super.onPointerDown(position, pointerId, offset, pointers);
    startPosition = position;
    startOffset = offset;
    _baselineAngle = _twoFingerAngle(pointers);
    _active = true;
  }

  @override
  void onPointerUp(int pointerId, Offset offset, Map<int, Offset> pointers) {
    super.onPointerUp(pointerId, offset, pointers);
    cancelTimer();
  }

  @override
  void onPointerMove(int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (!_active) return;
    super.onPointerMove(pointerId, offset, pointers);
    final newAngle = _twoFingerAngle(pointers);
    var delta = newAngle - _baselineAngle!;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    if (!_rotating) {
      if (delta.abs() > thresholdDeg) {
        _rotating = true;
      } else {
        return; // still pinch/drag
      }
    }
    mapModel.rotateBy(delta);
    _baselineAngle = newAngle;
  }

  double _normalize(double deg) {
    deg %= 360;
    return deg < 0 ? deg + 360 : deg;
  }

  /// returns the angle between the two fingers. Even if 3 fingers are required for rotation this method only uses the
  /// angle of the first 2 fingers. This should be sufficient in most cases.
  double _twoFingerAngle(Map<int, Offset> pointers) {
    final pts = pointers.values.toList();
    final theta = atan2(pts[1].dy - pts[0].dy, pts[1].dx - pts[0].dx);
    return _normalize(theta * 180 / pi);
  }
}
