import '../layer/job/job.dart';
import '../model/tile.dart';
import '../rendertheme/renderinfo.dart';
import '../rendertheme/shape/shape.dart';

/**
 * The LabelStore is an abstract store for labels from which it is possible to retrieve a priority-ordered
 * queue of items that are visible within a given bounding box for a zoom level.
 */
abstract class LabelStore {
  /**
   * Clears the data.
   */
  void clear();

  /**
   * Returns a version number, which changes every time an update is made to the LabelStore.
   *
   * @return the version number
   */
  int getVersion();

  /**
   * Gets the items that are visible on a set of tiles.
   *
   * @param upperLeft  tile in upper left corner of visible area.
   * @param lowerRight tile in lower right corner of visible area.
   * @return a list of MapElements that are visible on the tiles.
   */
  Map<Job, List<RenderInfo<Shape>>> getVisibleItems(Set<Job> jobs);

  bool hasTile(Tile tile);
}
