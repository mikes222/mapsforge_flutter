import '../../graphics/display.dart';
import '../../graphics/mapcanvas.dart';
import '../../model/mappoint.dart';
import '../../model/rectangle.dart';

/// The MapElementContainer is the abstract base class for annotations that can be placed on the
/// map, e.g. labels and icons.
/// <p/>
/// A MapElementContainer has a central pivot point, which denotes the geographic point for the entity
/// translated into absolute map pixels. The boundary denotes the space that the item requires
/// around this central point.
/// <p/>
/// A MapElementContainer has a priority (higher value means higher priority) that should be used to determine
/// the drawing order, i.e. elements with higher priority should be drawn before elements with lower
/// priority. If there is not enough space on the map, elements with lower priority should then not be
/// drawn.
abstract class MapElementContainer implements Comparable<MapElementContainer> {
  /// The space the item requires around the central point [xy]
  Rectangle? boundary;

  /// The space the item requires relative to the absolute coordinates in pixels
  Rectangle? boundaryAbsolute;

  final Display display;

  final int priority;

  /// The central pivot point which is the geographic point for the entity translated
  /// into absolute map pixels
  final Mappoint xy;

  MapElementContainer(this.xy, this.display, this.priority);

  /**
   * Compares elements according to their priority.
   *
   * @param other
   * @return priority order
   */
  @override
  int compareTo(MapElementContainer other) {
    return this.priority - other.priority;
  }

  /**
   * Drawing method: element will draw itself on canvas shifted by origin point of canvas.
   */
  void draw(MapCanvas canvas, Mappoint origin);

  /// Gets the pixel absolute boundary for this element.
  ///
  /// @return Rectangle with absolute pixel coordinates.
  Rectangle getBoundaryAbsolute() {
    boundaryAbsolute ??= this.boundary!.shift(xy);
    return boundaryAbsolute!;
  }

  bool intersects(Rectangle rectangle) {
    return this.getBoundaryAbsolute().intersects(rectangle);
  }

  /**
   * Returns if MapElementContainers clash with each other
   *
   * @param other element to test against
   * @return true if they overlap
   */
  bool clashesWith(MapElementContainer other) {
    // if either of the elements is always drawn, the elements do not clash
    if (Display.ALWAYS == this.display || Display.ALWAYS == other.display) {
      return false;
    }
    return this.getBoundaryAbsolute().intersects(other.getBoundaryAbsolute());
  }

  /**
   * Gets the center point of this element.
   *
   * @return Point with absolute center pixel coordinates.
   */
  Mappoint getPoint() {
    return this.xy;
  }

  int getPriority() {
    return priority;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapElementContainer &&
          runtimeType == other.runtimeType &&
          boundary == other.boundary &&
          display == other.display &&
          priority == other.priority &&
          xy == other.xy;

  @override
  int get hashCode =>
      (boundary?.hashCode ?? 15) ^
      display.hashCode ^
      priority.hashCode ^
      xy.hashCode;

  @override
  String toString() {
    return 'MapElementContainer{boundary: $boundary, boundaryAbsolute: $boundaryAbsolute, display: $display, priority: $priority, xy: $xy}';
  }
}
