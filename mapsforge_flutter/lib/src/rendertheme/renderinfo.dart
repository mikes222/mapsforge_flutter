import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_area.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_caption.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_circle.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_linesymbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_pathtext.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_polyline.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_symbol.dart';

import '../../../core.dart';
import '../../../maps.dart';
import '../graphics/mapcanvas.dart';
import '../model/maprectangle.dart';
import '../paintelements/shape_paint.dart';
import '../paintelements/shape_paint_area.dart';
import '../paintelements/shape_paint_caption.dart';
import '../paintelements/shape_paint_circle.dart';
import '../paintelements/shape_paint_linesymbol.dart';
import '../paintelements/shape_paint_pathtext.dart';
import '../paintelements/shape_paint_polyline.dart';
import '../paintelements/shape_paint_symbol.dart';

abstract class RenderInfo<T extends Shape> implements Comparable<RenderInfo> {
  final T shape;

  /// The boundary of this object in absolute pixels.
  MapRectangle? boundaryAbsolute;

  ShapePaint<T>? shapePaint;

  /// The caption to draw. (used by renderinstructionCaption)
  String? caption;

  RenderInfo(this.shape);

  void render(MapCanvas canvas, PixelProjection projection, Tile tile);

  MapRectangle getBoundaryAbsolute(PixelProjection projection);

  /// Returns if shapes clash with each other
  ///
  /// @param other element to test against
  /// @return true if they overlap
  bool clashesWith(RenderInfo other, PixelProjection projection);

  /// Returns true if this object intersects the given rectangle [other]. The rectangle
  /// represents absolute pixel-coordinates.
  bool intersects(MapRectangle other, PixelProjection projection);

  @override
  int compareTo(RenderInfo<Shape> other) {
    return shape.compareTo(other.shape);
  }

  String getShapeType() {
    return shape.getShapeType();
  }

  Future<void> createShapePaint(SymbolCache symbolCache) async {
    if (shapePaint != null) return;
    switch (shape.getShapeType()) {
      case "Area":
        // area
        shapePaint = ShapePaintArea(shape as ShapeArea) as ShapePaint<T>;
        await shapePaint!.init(symbolCache);
        break;
      case "Caption":

        /// we need to calculate the boundary for the caption. Remember that we cannot
        /// use ui code in isolates but here we are back again from isolates so we can
        /// calculate the width/height of the caption.
        shapePaint = ShapePaintCaption(shape as ShapeCaption, renderInfo: this)
            as ShapePaint<T>;
        break;
      case "Circle":
        shapePaint = ShapePaintCircle(shape as ShapeCircle) as ShapePaint<T>;
        break;
      // case "Hillshading":
      //   shapePaint = ShapePaintHillshading(shape as ShapeHillshading) as ShapePaint<T>;
      //   break;
      case "Linesymbol":
        shapePaint =
            ShapePaintLinesymbol(shape as ShapeLinesymbol) as ShapePaint<T>;
        await shapePaint!.init(symbolCache);
        break;
      case "Pathtext":
        shapePaint =
            ShapePaintPathtext(shape as ShapePathtext) as ShapePaint<T>;
        await shapePaint!.init(symbolCache);
        break;
      case "Polyline":
        // same as area but for open ways
        shapePaint =
            ShapePaintPolyline(shape as ShapePolyline) as ShapePaint<T>;
        await shapePaint!.init(symbolCache);
        break;
      case "Symbol":
        shapePaint = ShapePaintSymbol(shape as ShapeSymbol) as ShapePaint<T>;
        await shapePaint!.init(symbolCache);
        break;
      default:
        print(
            "cannot find ShapePaint for ${shape.getShapeType()} of type ${shape.runtimeType}");
    }
  }
}
