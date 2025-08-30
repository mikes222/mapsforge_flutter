import 'package:collection/collection.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_path.dart';

abstract class UiShapePainter<T extends Renderinstruction> extends ShapePainter<T> {
  UiShapePainter(super.renderinstruction);

  UiPath calculatePath(List<List<Mappoint>> coordinatesAbsolute, Mappoint reference, double dy) {
    UiPath path = UiPath();
    // omit holes in the area. Without this the hole is also drawn.
    path.setFillRule(MapFillRule.EVEN_ODD);
    for (var outerList in coordinatesAbsolute) {
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
}
