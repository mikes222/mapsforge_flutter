import 'package:dart_common/model.dart';
import 'package:datastore_renderer/ui.dart';

///
/// Implementations of this class provides caches for [Tile]s.
///
abstract class TileCache {
  ///
  /// disposes the cache. It should not be used anymore after disposing.
  ///
  void dispose();

  /// todo it may make sense to return a clone and dispose that clone at the consumer. The cache may evict an image at any time even if it is still used by the consumer.
  Future<TilePicture?> getOrProduce(Tile tile, Future<TilePicture?> Function(Tile) producer);

  ///
  /// Purges the whole cache. The cache can be used afterwards but will not return any items
  ///
  void purgeAll();

  ///
  /// Purges the cache whose [Tile]s intersects with the given [boundingBox]. Any bitmap which is fully or partially intersecting the
  /// given [boundingBox] will be purged.
  ///
  void purgeByBoundary(BoundingBox boundingBox);

  /// Returns the requested picture or null if the picture is not available.
  ///
  /// todo it may make sense to return a clone and dispose that clone at the consumer. The cache may evict an image at any time even if it is still used by the consumer.
  TilePicture? get(Tile tile);
}
