import 'package:mapsforge_flutter/src/graphics/matrix.dart';

class FlutterMatrix implements Matrix {
  //Matrix4 matrix = new Matrix4.identity();

  double? theta;

  double? pivotX;
  double? pivotY;

  // @override
  // void reset() {
  //   //this.matrix.setIdentity();
  // }

  /**
   * @param theta an angle measured in radians.
   */
  @override
  void rotate(double? theta, {double? pivotX = 0, double? pivotY = 0}) {
    this.theta = theta;
    this.pivotX = pivotX;
    this.pivotY = pivotY;
//    Vector3 angle = Vector3(pivotX, pivotY, 0);
//    matrix.rotate(angle, theta);
  }

  /**
   * Scale around center.
   *
   * @param scaleX the scale factor in x-direction
   * @param scaleY the scale factor in y-direction
   */
  // @override
  // void scale(double scaleX, double scaleY, {double pivotX, double pivotY}) {}
  //
  // @override
  // void translate(double translateX, double translateY) {
  //   //this.matrix.preTranslate(translateX, translateY);
  // }
}
