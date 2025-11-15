import 'dart:async';
import 'dart:ui';

import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/util/rotate_helper.dart';

class DefaultHandler {
  final int longPressDuration;

  Timer? _timer;

  final MapModel mapModel;

  late Size size;

  /// The maximum distance in pixels which the curser is allowed to move between tapDown and tapUp.
  final int maxDistance = 20;

  MapPosition? startPosition;

  Offset? startOffset;

  DefaultHandler({required this.longPressDuration, required this.mapModel});

  bool activeTimer() {
    return _timer != null;
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void setSize(Size size) {
    this.size = size;
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: longPressDuration), () {
      onTimeout();
    });
  }

  void onTimeout() {
    cancelTimer();
  }

  void onPointerDown(MapPosition position, int pointerId, Offset offset, Map<int, Offset> pointers) {
    startTimer();
    startPosition = position;
    startOffset = offset;
  }

  void onPointerUp(int pointerId, Offset offset, Map<int, Offset> pointers) {}

  void onPointerMove(int pointerId, Offset offset, Map<int, Offset> pointers) {}

  void onPointerCancel(int pointerId, Offset offset, Map<int, Offset> pointers) {
    cancelTimer();
  }

  TapEvent createEvent(Offset offset) {
    PositionInfo positionInfo = RotateHelper.normalize(startPosition!, size, offset.dx, offset.dy);
    // interpolate the new center between the old center and where we
    // pressed now. The new center is half-way between our double-pressed point and the old-center
    TapEvent tapEvent = TapEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: startPosition!.projection,
      mappoint: positionInfo.mappoint,
    );
    return tapEvent;
  }

  bool hasMoved(Offset offset) {
    if (startOffset == null) return false;
    if ((startOffset!.dx - offset.dx).abs() > maxDistance || (startOffset!.dy - offset.dy).abs() > maxDistance) {
      return true;
    }
    return false;
  }
}
