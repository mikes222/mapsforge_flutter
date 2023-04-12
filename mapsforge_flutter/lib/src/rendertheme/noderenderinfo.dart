import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinfo.dart';

import '../../core.dart';
import '../../maps.dart';
import '../graphics/display.dart';
import '../graphics/mapcanvas.dart';
import 'nodeproperties.dart';
import 'shape/shape.dart';

class NodeRenderInfo<T extends Shape> extends RenderInfo<T> {
  final NodeProperties nodeProperties;

  NodeRenderInfo(this.nodeProperties, T shapeSymbol) : super(shapeSymbol);

  @override
  void render(MapCanvas canvas, PixelProjection projection, Tile tile) {
    shapePaint!.renderNode(canvas, nodeProperties, projection, tile, this);
  }

  /// Returns true if shapes clash with each other
  ///
  /// @param other element to test against
  /// @return true if they overlap
  @override
  bool clashesWith(RenderInfo other, PixelProjection projection) {
    // if either of the elements is always drawn, the elements do not clash
    if (Display.ALWAYS == shape.display ||
        Display.ALWAYS == other.shape.display) {
      return false;
    }
    // print(
    //     "clashes ${getBoundaryAbsolute(projection).intersects(other.getBoundaryAbsolute(projection))} for ${getBoundaryAbsolute(projection)} (${shape.calculateBoundary()}) and ${other.getBoundaryAbsolute(projection)}");
    return getBoundaryAbsolute(projection)
        .intersects(other.getBoundaryAbsolute(projection));
  }

  /// Returns true if the current shape intersects with the given rectangle. This is
  /// used to find out if the current shape also needs to be drawn at a
  /// neighboring shape.
  @override
  bool intersects(MapRectangle other, PixelProjection projection) {
    //  print("intersects: ${getBoundaryAbsolute(projection).intersects(other)}");
    return this.getBoundaryAbsolute(projection).intersects(other);
  }

  @override
  MapRectangle getBoundaryAbsolute(PixelProjection projection) {
    if (boundaryAbsolute != null) return boundaryAbsolute!;
    MapRectangle boundary = shape.calculateBoundary();
    Mappoint mappoint = nodeProperties.getCoordinatesAbsolute(projection);
    boundaryAbsolute = boundary.shift(mappoint);
    //print("   boundAbs: ${boundaryAbsolute} ($boundary)");
    return boundaryAbsolute!;
  }
}
