import '../model/boundingbox.dart';

import 'bitmap.dart';

abstract class HillshadingBitmap extends Bitmap {
  /**
   * Return geo bounds of the area within the padding.
   */
  BoundingBox getAreaRect();

  /**
   * Optional padding (lies outside of areaRect).
   */
  int getPadding();
}

/////////////////////////////////////////////////////////////////////////////

enum Border {
  WEST
//(
//true
//)
  ,
  NORTH
//(false)
  ,
  EAST
//(true)
  ,
  SOUTH
//(false);

//public
//
//final boolean vertical;

//Border(boolean vertical) {
//  this.vertical = vertical;
//}
}
