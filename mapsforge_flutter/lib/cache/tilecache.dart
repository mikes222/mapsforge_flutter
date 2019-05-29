import '../graphics/tilebitmap.dart';
import '../queue/job.dart';

import '../model/observableinterface.dart';

/**
 * Interface for tile image caches.
 */
abstract class TileCache extends ObservableInterface {
  /**
   * @return true if this cache contains an image for the given key, false otherwise.
   * @see Map#containsKey
   */
  bool containsKey(Job key);

  /**
   * Destroys this cache.
   * <p/>
   * Applications are expected to call this method when they no longer require the cache.
   * <p/>
   * In versions prior to 0.5.1, it was common practice to call this method but continue using the cache, in order to
   * empty it, forcing all tiles to be re-rendered or re-requested from the source. Beginning with 0.5.1,
   * {@link #purge()} should be used for this purpose. The earlier practice is now discouraged and may lead to
   * unexpected results when used with features introduced in 0.5.1 or later.
   */
  void destroy();

  /**
   * @return the image for the given key or null, if this cache contains no image for the key.
   * @see Map#get
   */
  TileBitmap get(Job key);

  /**
   * @return the capacity of this cache.
   */
  int getCapacity();

  /**
   * @return the capacity of the first level of a multi-level cache.
   */
  int getCapacityFirstLevel();

  /**
   * Returns tileBitmap only if available at fastest cache in case of multi-layered cache, null otherwise.
   *
   * @return tileBitmap if available without getting from lower storage levels
   */
  TileBitmap getImmediately(Job key);

  /**
   * Purges this cache.
   * <p/>
   * Calls to {@link #get(Job)} issued after purging will not return any tiles added before the purge operation.
   * <p/>
   * Applications should purge the tile cache when map model parameters change, such as the render style for locally
   * rendered tiles, or the source for downloaded tiles. Applications which frequently alternate between a limited
   * number of map model configurations may want to consider using a different cache for each.
   *
   * @since 0.5.1
   */
  void purge();

  /**
   * @throws IllegalArgumentException if any of the parameters is {@code null}.
   * @see Map#put
   */
  void put(Job key, TileBitmap bitmap);

  /**
   * Reserves a working set in this cache, for multi-level caches this means bringing the elements in workingSet into
   * the fastest cache.
   */
  void setWorkingSet(Set<Job> workingSet);
}
