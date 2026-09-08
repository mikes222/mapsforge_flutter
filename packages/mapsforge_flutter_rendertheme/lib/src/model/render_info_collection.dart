import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/spatial_boundary_index.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/render_info.dart';

class RenderInfoCollection {
  final List<RenderInfo> renderInfos;

  RenderInfoCollection.empty() : renderInfos = [];

  RenderInfoCollection(this.renderInfos);

  void clear() {
    renderInfos.clear();
  }

  int get length => renderInfos.length;

  /// Transforms a list of MapElements, orders it and removes those elements that overlap.
  /// This operation is useful for an early elimination of elements in a list that will never
  /// be drawn because they overlap. Overlapping items will be disposed.
  ///
  /// @param input list of MapElements
  /// @return collision-free, ordered list, a subset of the input.
  void collisionFreeOrdered() {
    if (renderInfos.length <= 1) return;
    // sort items by priority (highest first)
    renderInfos.sort((a, b) => b.renderInstruction.priority.compareTo(a.renderInstruction.priority));
    // in order of priority, see if an item can be drawn, i.e. none of the items
    // in the currentItemsToDraw list clashes with it.
    // Use a spatial index to avoid an O(n²) collision scan.
    final SpatialBoundaryIndex<RenderInfo> spatialIndex = SpatialBoundaryIndex(cellSize: 16.0);
    final List<RenderInfo> output = [];
    for (RenderInfo item in renderInfos) {
      MapRectangle boundary = item.getBoundaryAbsolute();
      if (!spatialIndex.hasCollision(item, boundary)) {
        output.add(item);
        spatialIndex.add(item, boundary);
      } else {
        //item.dispose();
      }
    }
    renderInfos.clear();
    renderInfos.addAll(output);
  }
}
