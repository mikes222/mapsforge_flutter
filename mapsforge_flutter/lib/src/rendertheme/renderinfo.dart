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

///
/// In the terminal window run
///
///```
/// flutter packages pub run build_runner build --delete-conflicting-outputs
///```
///
abstract class RenderInfo<T extends Shape> implements Comparable<RenderInfo> {
  final T shape;

  /// The boundary of this object in absolute pixels.
  MapRectangle? boundaryAbsolute;

  ShapePaint<T>? shapePaint;

  /// The caption to draw. (used by renderinstructionCaption)
  String? caption;

  RenderInfo(this.shape);

  void render(MapCanvas canvas, PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]);

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
        if (shape.shapePaint != null) {
          shapePaint = shape.shapePaint! as ShapePaint<T>?;
        } else {
          shapePaint = ShapePaintArea(shape as ShapeArea) as ShapePaint<T>;
          await shapePaint!.init(symbolCache);
          shape.shapePaint = shapePaint;
        }
        break;
      case "Caption":

        /// we need to calculate the boundary for the caption. Remember that we cannot
        /// use ui code in isolates but here we are back again from isolates so we can
        /// calculate the width/height of the caption.
        shapePaint = ShapePaintCaption(shape as ShapeCaption, caption: caption!)
            as ShapePaint<T>;
        break;
      case "Circle":
        if (shape.shapePaint != null) {
          shapePaint = shape.shapePaint! as ShapePaint<T>?;
        } else {
          shapePaint = ShapePaintCircle(shape as ShapeCircle) as ShapePaint<T>;
          shape.shapePaint = shapePaint;
        }
        break;
      // case "Hillshading":
      //   shapePaint = ShapePaintHillshading(shape as ShapeHillshading) as ShapePaint<T>;
      //   break;
      case "Linesymbol":
        if (shape.shapePaint != null) {
          shapePaint = shape.shapePaint! as ShapePaint<T>?;
        } else {
          shapePaint =
              ShapePaintLinesymbol(shape as ShapeLinesymbol) as ShapePaint<T>;
          await shapePaint!.init(symbolCache);
        }
        break;
      case "Pathtext":
        shapePaint = ShapePaintPathtext(shape as ShapePathtext, caption!)
            as ShapePaint<T>;
        await shapePaint!.init(symbolCache);
        break;
      case "Polyline":
        // same as area but for open ways
        if (shape.shapePaint != null) {
          shapePaint = shape.shapePaint! as ShapePaint<T>?;
        } else {
          shapePaint =
              ShapePaintPolyline(shape as ShapePolyline) as ShapePaint<T>;
          await shapePaint!.init(symbolCache);
          shape.shapePaint = shapePaint;
        }
        break;
      case "Symbol":
        if (shape.shapePaint != null) {
          shapePaint = shape.shapePaint! as ShapePaint<T>?;
        } else {
          shapePaint = ShapePaintSymbol(shape as ShapeSymbol) as ShapePaint<T>;
          await shapePaint!.init(symbolCache);
          shape.shapePaint = shapePaint;
        }
        break;
      default:
        print(
            "cannot find ShapePaint for ${shape.getShapeType()} of type ${shape.runtimeType}");
    }
  }
}
