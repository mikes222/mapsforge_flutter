import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_path.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// An abstract base class for shape painters that provides a utility method for
/// converting a list of geo-coordinates into a `UiPath`.
abstract class UiShapePainter<T extends Renderinstruction> extends ShapePainter<T> {
  /// Creates a new `UiShapePainter`.
  UiShapePainter(super.renderinstruction);

  /// Calculates a `UiPath` from a list of absolute geo-coordinates.
  ///
  /// The coordinates are converted to pixel coordinates relative to the given
  /// [reference] point. The path's fill rule is set to `EVEN_ODD` to correctly
  /// handle polygons with holes.
  UiPath calculatePath(List<List<Mappoint>> coordinatesAbsolute, Mappoint reference, double dy) {
    UiPath path = UiPath();
    // omit holes in the area. Without this the hole is also drawn.
    path.setFillRule(MapFillRule.EVEN_ODD);
    for (var outerList in coordinatesAbsolute) {
      if (_isOutside(outerList, 5000)) continue;
      outerList.forEachIndexed((int idx, Mappoint point) {
        if (idx == 0) {
          path.moveToMappoint(point.offset(reference).offset(0, dy));
        } else {
          path.lineToMappoint(point.offset(reference).offset(0, dy));
        }
      });
    }
    return path;
  }

  bool _isOutside(List<Mappoint> outerList, int margin) {
    Mappoint? first = outerList.firstWhereOrNull((test) => test.x > -margin || test.x < margin);
    if (first == null) return true;
    first = outerList.firstWhereOrNull((test) => test.y > -margin || test.y < margin);
    if (first == null) return true;
    return false;
  }
}
