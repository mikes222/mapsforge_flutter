import 'package:mapsforge_flutter_core/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/src/model/map_display.dart';
import 'package:dart_rendertheme/src/model/render_context.dart';
import 'package:dart_rendertheme/src/model/render_info.dart';
import 'package:dart_rendertheme/src/model/wayproperties.dart';

///
/// In the terminal window run
///
///```
/// flutter packages pub run build_runner build --delete-conflicting-outputs
///```
///
class RenderInfoWay<T extends Renderinstruction> extends RenderInfo<T> {
  final WayProperties wayProperties;

  RenderInfoWay(this.wayProperties, super.renderInstruction, {super.caption});

  @override
  void render(RenderContext renderContext) {
    shapePainter!.renderWay(this, renderContext, wayProperties);
  }

  /// Returns if MapElementContainers clash with each other
  ///
  /// @param other element to test against
  /// @return true if they overlap
  @override
  bool clashesWith(RenderInfo other) {
    // if either of the elements is always drawn, the elements do not clash
    if (MapDisplay.ALWAYS == renderInstruction.display || MapDisplay.ALWAYS == other.renderInstruction.display) {
      return false;
    }
    return getBoundaryAbsolute().intersects(other.getBoundaryAbsolute());
  }

  @override
  bool intersects(MapRectangle other) {
    return getBoundaryAbsolute().intersects(other);
  }

  @override
  MapRectangle getBoundaryAbsolute() {
    if (boundaryAbsolute != null) return boundaryAbsolute!;
    boundaryAbsolute = wayProperties.getBoundaryAbsolute();
    return boundaryAbsolute!;
  }
}
