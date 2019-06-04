import 'package:mapsforge_flutter/src/graphics/matrix.dart';

class AndroidMatrix implements Matrix {
//  matrix = AffineTransform();

  @override
  void reset() {
    //  this.matrix.reset();
  }

  /**
   * @param theta an angle measured in radians.
   */
  @override
  void rotate(double theta, {double pivotX, double pivotY}) {}

  /**
   * Scale around center.
   *
   * @param scaleX the scale factor in x-direction
   * @param scaleY the scale factor in y-direction
   */
  @override
  void scale(double scaleX, double scaleY, {double pivotX, double pivotY}) {}

  @override
  void translate(double translateX, double translateY) {
    //this.matrix.preTranslate(translateX, translateY);
  }
}
