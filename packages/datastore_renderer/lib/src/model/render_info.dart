import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/cache/symbolcache.dart';
import 'package:datastore_renderer/src/model/linestring.dart';
import 'package:datastore_renderer/src/shapepainter/shape_paint.dart';
import 'package:datastore_renderer/src/shapepainter/shape_paint_area.dart';
import 'package:datastore_renderer/src/shapepainter/shape_paint_caption.dart';
import 'package:datastore_renderer/src/shapepainter/shape_paint_circle.dart';
import 'package:datastore_renderer/src/shapepainter/shape_paint_linesymbol.dart';
import 'package:datastore_renderer/src/shapepainter/shape_paint_pathtext.dart';
import 'package:datastore_renderer/src/shapepainter/shape_paint_polyline.dart';
import 'package:datastore_renderer/src/shapepainter/shape_paint_symbol.dart';
import 'package:datastore_renderer/src/ui/ui_canvas.dart';

///
/// In the terminal window run
///
///```
/// flutter packages pub run build_runner build --delete-conflicting-outputs
///```
///
abstract class RenderInfo<T extends Renderinstruction> implements Comparable<RenderInfo> {
  final T renderInstruction;

  /// The boundary of this object in absolute pixels. This is a cache and will
  /// be calculated by asking [ShapePaint] or [Shape].
  MapRectangle? boundaryAbsolute;

  ShapePaint<T>? shapePaint;

  /// The caption to draw. (used by renderinstructionCaption)
  String? caption;

  LineString? stringPath;

  RenderInfo(this.renderInstruction);

  void render(UiCanvas canvas, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]);

  MapRectangle getBoundaryAbsolute(PixelProjection projection);

  /// Returns if shapes clash with each other
  ///
  /// @param other element to test against
  /// @return true if they overlap
  bool clashesWith(RenderInfo other, PixelProjection projection);

  /// Returns true if this object intersects the given rectangle [other]. The rectangle
  /// represents absolute pixel-coordinates.
  bool intersects(MapRectangle other, PixelProjection projection);

  // @override
  // int compareTo(RenderInfo<RenderInstruction> other) {
  //   return renderInstruction.compareTo(other.renderInstruction);
  // }

  String getShapeType() {
    return renderInstruction.getType();
  }

  static int created = 0;

  Future<void> createShapePaint(SymbolCache symbolCache) async {
    if (shapePaint != null) return;
    if (renderInstruction.getPainter() != null) {
      shapePaint = renderInstruction.getPainter()! as ShapePaint<T>?;
      return;
    }
    switch (renderInstruction.getType()) {
      case "area":
        shapePaint = await ShapePaintArea.create(renderInstruction as RenderinstructionArea, symbolCache) as ShapePaint<T>;
        ++created;
        break;
      case "caption":

        /// we need to calculate the boundary for the caption. Remember that we cannot
        /// use ui code in isolates but here we are back again from isolates so we can
        /// calculate the width/height of the caption.
        shapePaint = await ShapePaintCaption.create(renderInstruction as RenderinstructionCaption, symbolCache, caption: caption!) as ShapePaint<T>;
        ++created;
        // since captions are dependent on the node/way properties we are not allowed to use this instance for other shapes, so do not assign it to shape.shapePaint
        break;
      case "circle":
        shapePaint = await ShapePaintCircle.create(renderInstruction as RenderinstructionCircle, symbolCache) as ShapePaint<T>;
        ++created;
        break;
      // case "Hillshading":
      //   shapePaint = ShapePaintHillshading(shape as ShapeHillshading) as ShapePaint<T>;
      //   break;
      case "linesymbol":
        shapePaint = await ShapePaintLinesymbol.create(renderInstruction as RenderinstructionLinesymbol, symbolCache) as ShapePaint<T>;
        ++created;
        break;
      case "pathtext":
        shapePaint = await ShapePaintPathtext.create(renderInstruction as RenderinstructionPathtext, symbolCache, caption!, stringPath!) as ShapePaint<T>;
        ++created;
        // since captions are dependent on the node/way properties we are not allowed to use this instance for other shapes, so do not assign it to shape.shapePaint
        break;
      case "polyline":
        // same as area but for open ways
        shapePaint = await ShapePaintPolyline.create(renderInstruction as RenderinstructionPolyline, symbolCache) as ShapePaint<T>;
        ++created;
        break;
      case "symbol":
        shapePaint = await ShapePaintSymbol.create(renderInstruction as RenderinstructionSymbol, symbolCache) as ShapePaint<T>;
        ++created;
        break;
      default:
        throw Exception("cannot find ShapePaint for ${renderInstruction.getType()} of type ${renderInstruction.runtimeType}");
    }
  }

  /// manually added
  @override
  String toString() {
    return 'RenderInfo{type: ${getShapeType()}}, boundaryAbsolute: ${boundaryAbsolute}';
  }
}
