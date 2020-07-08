import 'package:mapsforge_flutter/src/model/tile.dart';

import '../model/observableinterface.dart';

/// Interface for tile image caches.
abstract class TileCache extends ObservableInterface {
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

  ///
  /// Returns a tile from cache or creates a tile and stores it in cache
  Tile getTile(int x, int y, int zoomLevel, double tileSize);
}
