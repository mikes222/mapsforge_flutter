import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

import '../../graphics/mapcanvas.dart';
import '../../graphics/matrix.dart';
import '../../model/mappoint.dart';
import '../../model/rectangle.dart';
import 'mapelementcontainer.dart';

class SymbolContainer extends MapElementContainer {
  final bool alignCenter;

  final double? theta;

  final MapPaint paint;

  final ResourceBitmap bitmap;

  SymbolContainer(
      {required Mappoint point,
      required Display display,
      required int priority,
      required this.bitmap,
      this.theta,
      this.alignCenter = true,
      required this.paint})
      : super(point, display, priority) {
    if (alignCenter) {
      double halfWidth = bitmap.getWidth() / 2;
      double halfHeight = bitmap.getHeight() / 2;
      this.boundary =
          new Rectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
    } else {
      this.boundary = new Rectangle(
          0, 0, bitmap.getWidth().toDouble(), bitmap.getHeight().toDouble());
    }

    // we get the image from the [RenderSymbol] class which lives as long as we have the rendertheme. So no need to keep track of the short-living image here
    //this.symbol.incrementRefCount();
  }

  @override
  void dispose() {
    bitmap.dispose();
  }

  @override
  void draw(MapCanvas canvas, Mappoint origin) {
    //print("symbolcontainer ${xy.x - origin.x + boundary.left} / ${xy.y - origin.y + boundary.top} for ${symbol.toString()}");
    Matrix? matrix;
    if (theta != null && theta != 0) {
      matrix = GraphicFactory().createMatrix();
      if (alignCenter) {
        matrix.rotate(theta, pivotX: boundary!.left, pivotY: boundary!.top);
      } else {
        matrix.rotate(theta);
      }
    }

    //if (bitmap.debugDisposed())
    // print(
    //     "drawing ${bitmap} at ${this.xy.x - origin.x + boundary!.left} / ${this.xy.y - origin.y + boundary!.top} $theta"); //bitmap.debugGetOpenHandleStackTraces();
    //print(StackTrace.current);
    canvas.drawBitmap(
        bitmap: bitmap,
        matrix: matrix,
        left: this.xy.x - origin.x + boundary!.left,
        top: this.xy.y - origin.y + boundary!.top,
        paint: paint);
  }

  @override
  String toString() {
    return 'SymbolContainer{alignCenter: $alignCenter, theta: $theta, paint: $paint, super ${super.toString()}';
  }
}
