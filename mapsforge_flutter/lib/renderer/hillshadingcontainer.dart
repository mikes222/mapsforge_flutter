import '../graphics/bitmap.dart';
import '../model/rectangle.dart';

import 'shapecontainer.dart';
import 'shapetype.dart';

class HillshadingContainer implements ShapeContainer {
  final double magnitude;
  final Bitmap bitmap;
  final Rectangle hillsRect;
  final Rectangle tileRect;

  HillshadingContainer(
      this.bitmap, this.magnitude, this.hillsRect, this.tileRect);

  @override
  ShapeType getShapeType() {
    return ShapeType.HILLSHADING;
  }

  @override
  String toString() {
    return 'HillshadingContainer{magnitude: $magnitude, bitmap: $bitmap, hillsRect: $hillsRect, tileRect: $tileRect}';
  }
}
