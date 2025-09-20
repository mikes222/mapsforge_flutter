import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

/// A wrapper around Flutter's `Matrix4` to simplify 2D transformations.
///
/// This class provides a convenient way to perform rotations around a pivot
/// point, which is a common operation in map rendering.
class UiMatrix {
  final Matrix4 _matrix4;

  UiMatrix() : _matrix4 = Matrix4.identity();

  /// Rotates the matrix by [radians] around the given pivot point.
  ///
  /// If [pivotX] and [pivotY] are not specified, the rotation is around the origin (0,0).
  void rotate(double radians, {double pivotX = 0, double pivotY = 0}) {
    if (pivotX != 0 || pivotY != 0) {
      _matrix4.translateByDouble(-pivotX, -pivotY, 0, 1);
      _matrix4.rotateZ(radians);
      _matrix4.translateByDouble(pivotX, pivotY, 0, 1);
    } else {
      _matrix4.rotateZ(radians);
    }
  }

  /// for Canvas.drawPicture:
  ///         _uiCanvas.translate(left, top);
  //         _uiCanvas.translate(-fm.pivotX!, -fm.pivotY!);
  //         _uiCanvas.rotate(fm.theta!);
  //         _uiCanvas.translate(fm.pivotX!, fm.pivotY!);
  /// Exposes the underlying `Float64List` storage of the `Matrix4`.
  ///
  /// This is used for passing the matrix data to the Flutter engine.
  Float64List expose() => _matrix4.storage;
}
