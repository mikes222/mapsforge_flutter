import 'dart:ui';

import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/gesture/default_handler.dart';

class DoubleTapHandler extends DefaultHandler {
  //  int _tapUpCount = 0;

  DoubleTapHandler({required super.longPressDuration, required super.mapModel});

  // @override
  // void cancelTimer() {
  //   super.cancelTimer();
  //   //  _tapUpCount = 0;
  // }

  @override
  void onPointerDown(MapPosition position, int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (pointers.length > 1) {
      cancelTimer();
      return;
    }
    if (activeTimer()) {
      cancelTimer();
      mapModel.doubleTap(createEvent(offset));
      return;
    }
    super.onPointerDown(position, pointerId, offset, pointers);
  }

  // @override
  // void onPointerUp(int pointerId, Offset offset, Map<int, Offset> pointers) {
  //   if (!activeTimer()) return;
  //   super.onPointerUp(pointerId, offset, pointers);
  //   ++_tapUpCount;
  // }
}
