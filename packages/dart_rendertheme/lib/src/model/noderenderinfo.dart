import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/src/model/nodeproperties.dart';
import 'package:dart_rendertheme/src/model/render_info.dart';

class NodeRenderInfo<T extends Renderinstruction> extends RenderInfo<T> {
  final NodeProperties nodeProperties;

  NodeRenderInfo(this.nodeProperties, T renderInstruction) : super(renderInstruction);

  /// Returns true if shapes clash with each other
  ///
  /// @param other element to test against
  /// @return true if they overlap
  // @override
  // bool clashesWith(RenderInfo other, PixelProjection projection) {
  //   // if either of the elements is always drawn, the elements do not clash
  //   if (Display.ALWAYS == renderInstruction.display || Display.ALWAYS == other.renderInstruction.display) {
  //     return false;
  //   }
  //   return getBoundaryAbsolute(projection).intersects(other.getBoundaryAbsolute(projection));
  // }
  //
  // /// Returns true if the current shape intersects with the given rectangle. This is
  // /// used to find out if the current shape also needs to be drawn at a
  // /// neighboring shape.
  // @override
  // bool intersects(MapRectangle other, PixelProjection projection) {
  //   //  print("intersects: ${getBoundaryAbsolute(projection).intersects(other)}");
  //   return getBoundaryAbsolute(projection).intersects(other);
  // }
  //
  // @override
  // MapRectangle getBoundaryAbsolute(PixelProjection projection) {
  //   if (boundaryAbsolute != null) return boundaryAbsolute!;
  //   MapRectangle boundary = shapePaint?.calculateBoundary() ?? shape.calculateBoundary();
  //   Mappoint mappoint = nodeProperties.getCoordinatesAbsolute(projection);
  //   boundaryAbsolute = boundary.shift(mappoint);
  //   return boundaryAbsolute!;
  // }
}
