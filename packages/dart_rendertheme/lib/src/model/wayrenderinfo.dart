import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/src/model/render_info.dart';
import 'package:dart_rendertheme/src/model/wayproperties.dart';

///
/// In the terminal window run
///
///```
/// flutter packages pub run build_runner build --delete-conflicting-outputs
///```
///
class WayRenderInfo<T extends Renderinstruction> extends RenderInfo<T> {
  final WayProperties wayProperties;

  WayRenderInfo(this.wayProperties, T renderInstruction) : super(renderInstruction);

  /// Returns if MapElementContainers clash with each other
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
  // @override
  // bool intersects(MapRectangle other, PixelProjection projection) {
  //   return this.getBoundaryAbsolute(projection).intersects(other);
  // }
  //
  // @override
  // MapRectangle getBoundaryAbsolute(PixelProjection projection) {
  //   if (boundaryAbsolute != null) return boundaryAbsolute!;
  //   boundaryAbsolute = wayProperties.getBoundary(projection);
  //   return boundaryAbsolute!;
  // }
}
