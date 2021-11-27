import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'dart:ui' as ui;

class FlutterColor {
  static int getColor(Color color) {
    switch (color) {
      case Color.BLACK:
        return Colors.black.value;
      case Color.BLUE:
        return Colors.blue.value;
      case Color.GREEN:
        return Colors.green.value;
      case Color.RED:
        return Colors.red.value;
      case Color.TRANSPARENT:
        return Colors.transparent.value;
      case Color.WHITE:
        return Colors.white.value;
    }

    //throw new Exception("unknown color: " + color.toString());
  }
}
