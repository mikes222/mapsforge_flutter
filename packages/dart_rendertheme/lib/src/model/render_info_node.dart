import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/src/model/display.dart';

class RenderInfoNode<T extends Renderinstruction> extends RenderInfo<T> {
  final NodeProperties nodeProperties;

  RenderInfoNode(this.nodeProperties, T renderInstruction) : super(renderInstruction);

  @override
  void render(RenderContext renderContext) {
    shapePainter!.renderNode(renderContext, nodeProperties);
  }

  // Returns true if shapes clash with each other
  //
  // @param other element to test against
  // @return true if they overlap
  @override
  bool clashesWith(RenderInfo other) {
    // if either of the elements is always drawn, the elements do not clash
    if (Display.ALWAYS == renderInstruction.display || Display.ALWAYS == other.renderInstruction.display) {
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
    MapRectangle boundary = shapePainter!.getBoundary();
    Mappoint mappoint = nodeProperties.getCoordinatesAbsolute();
    boundaryAbsolute = boundary.shift(mappoint);
    return boundaryAbsolute!;
  }
}
