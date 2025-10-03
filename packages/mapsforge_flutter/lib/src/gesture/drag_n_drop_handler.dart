import 'dart:ui';

import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/gesture/default_handler.dart';
import 'package:mapsforge_flutter/src/util/rotate_helper.dart';

class DragNdropHandler extends DefaultHandler {
  DragNdropStatus status = DragNdropStatus.start;

  DragNdropHandler({required super.longPressDuration, required super.mapModel});

  @override
  void onTimeout() {
    mapModel.dragNdrop(_createEvent(DragNdropEventType.start, startOffset!));
    status = DragNdropStatus.move;
    super.onTimeout();
  }

  @override
  void onPointerDown(MapPosition position, int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (pointers.length > 1) {
      if (status == DragNdropStatus.move) mapModel.dragNdrop(_createEvent(DragNdropEventType.cancel, startOffset!));
      cancelTimer();
      status = DragNdropStatus.start;
      return;
    }
    super.onPointerDown(position, pointerId, offset, pointers);
  }

  @override
  void onPointerUp(int pointerId, Offset offset, Map<int, Offset> pointers) {
    super.onPointerUp(pointerId, offset, pointers);
    if (status == DragNdropStatus.start) {
      cancelTimer();
    } else {
      if (hasMoved(offset)) {
        mapModel.dragNdrop(_createEvent(DragNdropEventType.finish, offset));
      } else {
        mapModel.dragNdrop(_createEvent(DragNdropEventType.cancel, offset));
      }
      cancelTimer();
      status = DragNdropStatus.start;
    }
  }

  @override
  void onPointerMove(int pointerId, Offset offset, Map<int, Offset> pointers) {
    super.onPointerMove(pointerId, offset, pointers);
    if (status == DragNdropStatus.start) {
      if (hasMoved(offset)) {
        cancelTimer();
        return;
      }
    } else {
      mapModel.dragNdrop(_createEvent(DragNdropEventType.move, offset));
    }
  }

  DragNdropEvent _createEvent(DragNdropEventType type, Offset offset) {
    PositionInfo positionInfo = RotateHelper.normalize(startPosition!, size, offset.dx, offset.dy);

    DragNdropEvent tapEvent = DragNdropEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: startPosition!.projection,
      mappoint: positionInfo.mappoint,
      type: type,
    );
    return tapEvent;
  }
}

//////////////////////////////////////////////////////////////////////////////

enum DragNdropStatus { start, move }
