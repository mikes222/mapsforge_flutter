import '../../graphics/display.dart';
import '../../model/maprectangle.dart';
import '../../paintelements/shape_paint.dart';
import '../nodeproperties.dart';
import '../rendercontext.dart';
import '../wayproperties.dart';

/// These subclasses defines the zoomlevel-dependent properties of the shapes. It will
/// be created by the renderinstructions and used to define how to draw a shape.
/// Since we want to create shapes in isolates we are not allowed to use any
/// ui-dependent classes here hence the [ShapePaint] classes which will created
/// by [RenderInfo] later.
class Shape implements Comparable<Shape> {
  String? category;

  Display display = Display.IFSPACE;

  int priority = 0;

  /// The boundary of this object in pixels relative to the center of the
  /// corresponding node or way. This is a cache and will be calculated by asking.
  MapRectangle? boundary = null;

  /// A cache for paint objects. Note that not every painter can be reused. Painters which
  /// depends on the given way/node cannot be cached.
  ShapePaint? shapePaint;

  int level = 0;

  Shape.base({required this.level});

  Shape.scale(Shape base, int zoomLevel) {
    display = base.display;
    priority = base.priority;
    level = base.level;
  }

  /// The boundary of this object in pixels relative to the center of the
  /// corresponding node or way
  MapRectangle calculateBoundary() {
    throw UnimplementedError();
    //return boundary ?? const MapRectangle(-10, -10, 10, 10);
  }

  /// Compares elements according to their priority.
  ///
  /// @param other
  /// @return priority order
  @override
  int compareTo(Shape other) {
    return this.priority - other.priority;
  }

  String getShapeType() {
    return "Unknown";
  }

  /// @param renderCallback a reference to the receiver of all render callbacks.
  /// @param renderContext
  /// @param poi
  void renderNode(
      final RenderContext renderContext, NodeProperties nodeProperties) {
    throw UnimplementedError();
  }

  /// @param renderCallback a reference to the receiver of all render callbacks.
  /// @param renderContext
  /// @param poi
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    throw UnimplementedError();
  }

  @override
  String toString() {
    return 'Shape{category: $category, display: $display, priority: $priority, level: $level}';
  }
}
