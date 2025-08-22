import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

class UiMatrix {
  final Matrix4 _matrix4;

  UiMatrix() : _matrix4 = Matrix4.identity();

  /// Rotates the matrix around the given pivot points
  /// @param radians an angle measured in radians.
  void rotate(double radians, {double pivotX = 0, double pivotY = 0}) {
    if (pivotX != 0 || pivotY != 0) {
      _matrix4.translateByDouble(pivotX, pivotY, 0, 1);
      _matrix4.rotateZ(radians);
      _matrix4.translateByDouble(-pivotX, -pivotY, 0, 1);
    } else {
      _matrix4.rotateZ(radians);
    }
  }

  /// for Canvas.drawPicture:
  ///         _uiCanvas.translate(left, top);
  //         _uiCanvas.translate(-fm.pivotX!, -fm.pivotY!);
  //         _uiCanvas.rotate(fm.theta!);
  //         _uiCanvas.translate(fm.pivotX!, fm.pivotY!);
  Float64List expose() => _matrix4.storage;
}
