import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

import '../../graphics/filter.dart';
import '../../graphics/mapcanvas.dart';
import '../../graphics/matrix.dart';
import '../../model/mappoint.dart';
import '../../model/rectangle.dart';
import 'mapelementcontainer.dart';

class SymbolContainer extends MapElementContainer {
  final bool alignCenter;

  //final Bitmap symbol;
  final String bitmapSrc;

  final int bitmapHeight;

  final int bitmapWidth;

  final double? theta;

  final MapPaint paint;

  SymbolContainer(
      {required Mappoint point,
      required Display display,
      required int priority,
      required this.bitmapSrc,
      required this.bitmapWidth,
      required this.bitmapHeight,
      this.theta,
      this.alignCenter = true,
      required this.paint})
      : super(point, display, priority) {
    if (alignCenter) {
      double halfWidth = bitmapWidth / 2;
      double halfHeight = bitmapHeight / 2;
      this.boundary =
          new Rectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
    } else {
      this.boundary =
          new Rectangle(0, 0, bitmapWidth.toDouble(), bitmapHeight.toDouble());
    }

    // we get the image from the [RenderSymbol] class which lives as long as we have the rendertheme. So no need to keep track of the short-living image here
    //this.symbol.incrementRefCount();
  }

  @mustCallSuper
  @override
  dispose() {
    //symbol.decrementRefCount();
  }

  @override
  Future<void> draw(
      MapCanvas canvas, Mappoint origin, SymbolCache symbolCache) async {
    //matrix.reset();
    // We cast to int for pixel perfect positioning
    //matrix.translate((this.xy.x - origin.x + boundary.left), (this.xy.y - origin.y + boundary.top));
    ResourceBitmap? bitmap =
        await symbolCache.getSymbol(bitmapSrc, bitmapWidth, bitmapHeight);
    if (bitmap == null) return;
    //print("symbolcontainer ${xy.x - origin.x + boundary.left} / ${xy.y - origin.y + boundary.top} for ${symbol.toString()}");

    Matrix? matrix;
    if (theta != null && theta != 0) {
      matrix = GraphicFactory().createMatrix();
      if (alignCenter) {
        matrix.rotate(theta, pivotX: -boundary!.left, pivotY: -boundary!.top);
      } else {
        matrix.rotate(theta);
      }
    }

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
