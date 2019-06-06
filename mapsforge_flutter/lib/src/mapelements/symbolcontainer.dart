import '../graphics/bitmap.dart';
import '../graphics/filter.dart';
import '../graphics/mapcanvas.dart';
import '../graphics/matrix.dart';
import '../model/mappoint.dart';
import '../model/rectangle.dart';
import 'mapelementcontainer.dart';

class SymbolContainer extends MapElementContainer {
  final bool alignCenter;
  Bitmap symbol;
  final double theta;

  SymbolContainer(point, display, priority, this.symbol, {this.theta, this.alignCenter = false}) : super(point, display, priority) {
    if (alignCenter) {
      double halfWidth = this.symbol.getWidth() / 2;
      double halfHeight = this.symbol.getHeight() / 2;
      this.boundary = new Rectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
    } else {
      this.boundary = new Rectangle(0, 0, this.symbol.getWidth().toDouble(), this.symbol.getHeight().toDouble());
    }

    this.symbol.incrementRefCount();
  }

  @override
  void draw(MapCanvas canvas, Mappoint origin, Matrix matrix, Filter filter) {
//    matrix.reset();
//    // We cast to int for pixel perfect positioning
//    matrix.translate((this.xy.x - origin.x + boundary.left), (this.xy.y - origin.y + boundary.top));
//    if (theta != 0 && alignCenter) {
//      matrix.rotate(theta, pivotX: -boundary.left, pivotY: -boundary.top);
//    } else {
//      matrix.rotate(theta);
//    }
    //print("symbolcontainer ${xy.x - origin.x + boundary.left} / ${xy.y - origin.y + boundary.top} for ${symbol.toString()}");
    canvas.drawBitmap(
        bitmap: this.symbol,
        matrix: matrix,
        filter: filter,
        left: this.xy.x - origin.x + boundary.left,
        top: this.xy.y - origin.y + boundary.top);
  }
}
