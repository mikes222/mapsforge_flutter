import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinfo.dart';

import '../../core.dart';
import '../../maps.dart';
import '../graphics/display.dart';
import '../graphics/mapcanvas.dart';
import '../renderer/minmaxmappoint.dart';
import '../renderer/rendererutils.dart';
import 'shape/shape.dart';
import 'wayproperties.dart';

///
/// In the terminal window run
///
///```
/// flutter packages pub run build_runner build --delete-conflicting-outputs
///```
///
class WayRenderInfo<T extends Shape> extends RenderInfo<T> {
  final WayProperties wayProperties;

  WayRenderInfo(this.wayProperties, T shape) : super(shape);

  @override
  void render(MapCanvas canvas, PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {
    shapePaint!.renderWay(
        canvas, wayProperties, projection, leftUpper, rotationRadian);
  }

  /// Returns if MapElementContainers clash with each other
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
    return getBoundaryAbsolute(projection)
        .intersects(other.getBoundaryAbsolute(projection));
  }

  @override
  bool intersects(MapRectangle other, PixelProjection projection) {
    return this.getBoundaryAbsolute(projection).intersects(other);
  }

  @override
  MapRectangle getBoundaryAbsolute(PixelProjection projection) {
    if (boundaryAbsolute != null) return boundaryAbsolute!;
    List<List<Mappoint>> coordinates =
    wayProperties.getCoordinatesAbsolute(projection);
    List<Mappoint>? c;
    double dy = 0;
    if (dy == 0) {
      c = coordinates[0];
    } else {
      c = RendererUtils.parallelPath(coordinates[0], dy);
    }
    MinMaxMappoint minMax = MinMaxMappoint(c);
    boundaryAbsolute =
        MapRectangle(minMax.minX, minMax.minY, minMax.maxX, minMax.maxY);
    return boundaryAbsolute!;
  }
}
