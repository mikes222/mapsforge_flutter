import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

class UiMatrix {
  Matrix4 _matrix4;

  UiMatrix() : _matrix4 = Matrix4.identity();

  /// @param theta an angle measured in radians.
  void rotate(double? theta, {double? pivotX = 0, double? pivotY = 0}) {
    // this.theta = theta;
    // this.pivotX = pivotX;
    // this.pivotY = pivotY;
  }

  /// for Canvas.drawPicture:
  ///         _uiCanvas.translate(left, top);
  //         _uiCanvas.translate(-fm.pivotX!, -fm.pivotY!);
  //         _uiCanvas.rotate(fm.theta!);
  //         _uiCanvas.translate(fm.pivotX!, fm.pivotY!);
  Float64List expose() => _matrix4.storage;
}
