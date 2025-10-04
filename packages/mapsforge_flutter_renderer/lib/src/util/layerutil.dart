import 'package:mapsforge_flutter_renderer/src/util/spatial_boundary_index.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

/// A utility class for handling layer-related operations, such as collision
/// detection and removal.
class LayerUtil {
  static bool _haveSpace(RenderInfo item, List<RenderInfo> list) {
    for (RenderInfo outputElement in list) {
      if (outputElement.clashesWith(item)) {
        return false;
      }
    }
    return true;
  }

  /// Removes elements from [addElements] that collide with elements in [keepElements]
  /// or with other elements in [addElements].
  ///
  /// This method uses a spatial index for efficient collision detection when dealing
  /// with a large number of elements.
  static List<RenderInfo> removeCollisions(List<RenderInfo> addElements, List<RenderInfo> keepElements) {
    // Use spatial indexing for better performance when dealing with many elements
    if (addElements.length > 10 || keepElements.length > 10) {
      return _removeCollisionsWithSpatialIndex(addElements, keepElements);
    }

    // Use original algorithm for small lists
    List<RenderInfo> toDraw2 = [];
    for (var newElement in addElements) {
      if (_haveSpace(newElement, keepElements)) {
        toDraw2.add(newElement);
      } else {
        //newElement.dispose();
      }
    }
    return toDraw2;
  }

  /// Optimized collision removal using spatial indexing
  static List<RenderInfo> _removeCollisionsWithSpatialIndex(List<RenderInfo> addElements, List<RenderInfo> keepElements) {
    final spatialIndex = SpatialBoundaryIndex(cellSize: 128.0);

    // Add all keep elements to spatial index
    for (final element in keepElements) {
      spatialIndex.add(element, element.getBoundaryAbsolute());
    }

    final toDraw = <RenderInfo>[];

    // Check each new element against spatial index
    for (final newElement in addElements) {
      if (!spatialIndex.hasCollision(newElement, newElement.getBoundaryAbsolute())) {
        toDraw.add(newElement);
        spatialIndex.add(newElement, newElement.getBoundaryAbsolute()); // Add to index for subsequent collision checks
      }
    }

    return toDraw;
  }
}
