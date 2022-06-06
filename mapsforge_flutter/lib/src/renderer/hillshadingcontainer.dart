import '../graphics/bitmap.dart';
import '../model/rectangle.dart';
import 'shapecontainer.dart';

class HillshadingContainer implements ShapeContainer {
  final double magnitude;
  final Bitmap? bitmap;
  final Rectangle? hillsRect;
  final Rectangle? tileRect;

  const HillshadingContainer(
      this.bitmap, this.magnitude, this.hillsRect, this.tileRect);

  @override
  String toString() {
    return 'HillshadingContainer{magnitude: $magnitude, bitmap: $bitmap, hillsRect: $hillsRect, tileRect: $tileRect}';
  }
}
