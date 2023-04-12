import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_symbol.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayproperties.dart';

import '../../maps.dart';
import '../../special.dart';
import '../graphics/matrix.dart';
import '../graphics/resourcebitmap.dart';
import '../model/maprectangle.dart';
import '../rendertheme/nodeproperties.dart';
import '../rendertheme/noderenderinfo.dart';
import '../rendertheme/wayrenderinfo.dart';

class ShapePaintSymbol extends ShapePaint<ShapeSymbol> {
  late final MapPaint fill;

  ResourceBitmap? bitmap;

  ShapePaintSymbol(ShapeSymbol shapeSymbol) : super(shapeSymbol) {
    fill = createPaint(style: Style.FILL);
  }

  @override
  Future<void> init(SymbolCache symbolCache) async {
    if (shape.bitmapSrc != null) {
      bitmap = await createBitmap(
          symbolCache: symbolCache,
          bitmapSrc: shape.bitmapSrc!,
          bitmapWidth: shape.getBitmapWidth(),
          bitmapHeight: shape.getBitmapHeight());
    }
  }

  @override
  void renderNode(MapCanvas canvas, NodeProperties nodeProperties,
      PixelProjection projection, Tile tile, NodeRenderInfo renderInfo) {
    if (bitmap == null) return;
    Mappoint point =
        nodeProperties.getCoordinateRelativeToTile(projection, tile);
    MapRectangle boundary = shape.calculateBoundary();
    //print("paint symbol boundar: $boundary");
    Matrix? matrix;
    if (shape.theta != 0) {
      matrix = GraphicFactory().createMatrix();
      matrix.rotate(shape.theta, pivotX: boundary.left, pivotY: boundary.top);
//        matrix.rotate(shapeSymbol.theta);
    }

    //if (bitmap.debugDisposed())
    // print(
    //     "drawing ${bitmap} at ${this.xy.x - origin.x + boundary!.left} / ${this.xy.y - origin.y + boundary!.top} $theta"); //bitmap.debugGetOpenHandleStackTraces();
    //print(StackTrace.current);
    canvas.drawBitmap(
        bitmap: bitmap!,
        matrix: matrix,
        left: point.x + boundary.left,
        top: point.y + boundary.top,
        paint: fill);
  }

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties,
      PixelProjection projection, Tile tile, WayRenderInfo renderInfo) {
    if (bitmap == null) return;
    Mappoint point = wayProperties.getCenterRelativeToTile(projection, tile, 0);
    MapRectangle boundary = shape.calculateBoundary();
    Matrix? matrix;
    if (shape.theta != 0) {
      matrix = GraphicFactory().createMatrix();
      matrix.rotate(shape.theta, pivotX: boundary.left, pivotY: boundary.top);
    }

    //if (bitmap.debugDisposed())
    // print(
    //     "drawing ${bitmap} at ${this.xy.x - origin.x + boundary!.left} / ${this.xy.y - origin.y + boundary!.top} $theta"); //bitmap.debugGetOpenHandleStackTraces();
    //print(StackTrace.current);
    canvas.drawBitmap(
        bitmap: bitmap!,
        matrix: matrix,
        left: point.x + boundary.left,
        top: point.y + boundary.top,
        paint: fill);
  }
}
