import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

class RenderInfoNode<T extends Renderinstruction> extends RenderInfo<T> {
  final NodeProperties nodeProperties;

  /// used for linesymbol and polyline_text
  final double rotateRadians;

  RenderInfoNode(this.nodeProperties, T renderinstruction, {this.rotateRadians = 0, super.caption}) : super(renderinstruction);

  @override
  void render(RenderContext renderContext) {
    shapePainter!.renderNode(this, renderContext, nodeProperties);
  }

  // Returns true if shapes clash with each other
  //
  // @param other element to test against
  // @return true if they overlap
  @override
  bool clashesWith(RenderInfo other) {
    // if either of the elements is always drawn, the elements do not clash
    if (MapDisplay.ALWAYS == renderInstruction.display || MapDisplay.ALWAYS == other.renderInstruction.display) {
      return false;
    }
    return getBoundaryAbsolute().intersects(other.getBoundaryAbsolute());
  }

  /// Returns true if the current shape intersects with the given rectangle. This is
  /// used to find out if the current shape also needs to be drawn at a
  /// neighboring shape.
  @override
  bool intersects(MapRectangle other) {
    return getBoundaryAbsolute().intersects(other);
  }

  @override
  MapRectangle getBoundaryAbsolute() {
    if (boundaryAbsolute != null) return boundaryAbsolute!;
    MapRectangle boundary = renderInstruction.getBoundary(this);
    Mappoint mappoint = nodeProperties.getCoordinatesAbsolute();
    boundaryAbsolute = boundary.shift(mappoint);
    return boundaryAbsolute!;
  }

  @override
  String toString() {
    return 'RenderInfoNode{nodeProperties: $nodeProperties, rotateRadians: $rotateRadians, super: ${super.toString()}}';
  }
}
