abstract class Matrix {
  //void reset();

  /**
   * @param theta an angle measured in radians.
   */
  void rotate(double? theta, {double? pivotX, double? pivotY});

  /**
   * Scale around center.
   *
   * @param scaleX the scale factor in x-direction
   * @param scaleY the scale factor in y-direction
   */
  // void scale(double scaleX, double scaleY, {double pivotX, double pivotY});

  // void translate(double translateX, double translateY);
}
