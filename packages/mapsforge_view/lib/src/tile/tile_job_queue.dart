import 'dart:async';

import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/cache/tile_cache.dart';
import 'package:mapsforge_view/src/tile/tile_dimension.dart';
import 'package:mapsforge_view/src/tile/tile_set.dart';
import 'package:mapsforge_view/src/util/tile_helper.dart';
import 'package:rxdart/rxdart.dart';
import 'package:task_queue/task_queue.dart';

import '../cache/memory_tile_cache.dart';

class TileJobQueue {
  final MapModel mapModel;

  MapSize? _size;

  TileCache tileCache = MemoryTileCache.create();

  static _CurrentJob? _currentJob;

  StreamSubscription<MapPosition>? _subscription;

  final Subject<TileSet> _tileStream = PublishSubject<TileSet>();

  /// Parallel task queue for tile loading optimization
  late final TaskQueue _tileTaskQueue;

  /// Maximum number of concurrent tile loading operations
  static const int _maxConcurrentTiles = 4;

  /// Stream emission batching timer
  Timer? _batchTimer;
  TileSet? _batchTileset;

  TileJobQueue({required this.mapModel}) {
    _tileTaskQueue = ParallelTaskQueue(_maxConcurrentTiles);

    _subscription = mapModel.positionStream.listen((MapPosition position) {
      if (_currentJob?.position == position) {
        return;
      }
      TileDimension tileDimension = TileHelper.calculateTiles(mapViewPosition: position, screensize: _size!);
      if (_currentJob?.tileDimension.contains(tileDimension) ?? false) {
        if (_currentJob!._done) {
          _emitTileSetBatched(_currentJob!.tileSet);
        } else {
          // same information to draw, previous job is still running
          return;
        }
      }
      _currentJob?.abort();
      unawaited(_positionEvent(position, tileDimension));
    });
  }

  void dispose() {
    _currentJob?.abort();
    _subscription?.cancel();
    _tileTaskQueue.cancel();
    _batchTimer?.cancel();
    _tileStream.close();
    _batchTileset = null;
  }

  /// Sets the current size of the mapview so that we know which and how many tiles we need for the whole view
  void setSize(double width, double height) {
    _size = MapSize(width: width, height: height);
  }

  MapSize? getSize() => _size;

  Future<void> _positionEvent(MapPosition position, TileDimension tileDimension) async {
    // stop if we do not yet have a size of the view
    if (_size == null) return;
    TileSet tileSet = TileSet(center: position.getCenter(), mapPosition: position);
    _CurrentJob myJob = _CurrentJob(position, tileDimension, tileSet);
    _currentJob = myJob;
    List<Tile> tiles = _createTiles(mapPosition: position, tileDimension: tileDimension);

    // retrieve all available tiles from cache
    for (Tile tile in tiles) {
      TilePicture? picture = tileCache.get(tile);
      if (picture != null) tileSet.images[tile] = picture;
    }
    if (myJob._abort) return;
    if (tileSet.images.isNotEmpty) {
      /// send the available tiles to ui with batching
      _emitTileSetBatched(tileSet);
    }

    // Load missing tiles in parallel using task queue
    final missingTiles = tiles.where((tile) => tileSet.images[tile] == null).toList();
    final futures = <Future<void>>[];

    for (Tile tile in missingTiles) {
      if (myJob._abort) break;

      final future = _tileTaskQueue.add(() async {
        if (myJob._abort) return;

        TilePicture? picture = await tileCache.getOrProduce(tile, (Tile tile) async {
          JobResult result = await mapModel.renderer.executeJob(JobRequest(tile));
          if (result.picture == null) return ImageHelper().createNoDataBitmap();
          // make sure the picture is converted to an image
          await result.picture!.convertPictureToImage();
          return result.picture!;
        });

        if (myJob._abort) return;
        if (picture != null) {
          tileSet.images[tile] = picture;
          _emitTileSetBatched(tileSet);
        }
      });

      futures.add(future);
    }

    // Wait for all tile loading to complete
    await Future.wait(futures);

    if (!myJob._abort) {
      myJob._done = true;
      // Start prefetching neighboring tiles
      //_prefetchNeighboringTiles(position, tileDimension);
    }
  }

  Stream<TileSet> get tileStream => _tileStream.stream;

  /// Emit tile set with batching to reduce stream emissions
  void _emitTileSetBatched(TileSet tileSet) {
    _batchTileset = tileSet;
    // Set new timer for batching
    _batchTimer ??= Timer(const Duration(milliseconds: 16), () {
      // ~60fps
      _batchTimer = null;
      if (_batchTileset != null) {
        _tileStream.add(_batchTileset!);
      }
    });
  }

  ///
  /// Get all tiles needed for a given view. The tiles are in the order where it makes most sense for
  /// the user (tile in the middle should be created first
  ///
  List<Tile> _createTiles({required MapPosition mapPosition, required TileDimension tileDimension}) {
    int zoomLevel = mapPosition.zoomlevel;
    int indoorLevel = mapPosition.indoorLevel;
    Mappoint center = mapPosition.getCenter();
    // shift the center to the left-upper corner of a tile since we will calculate the distance to the left-upper corners of each tile
    RelativeMappoint relative = center.offset(Mappoint(MapsforgeSettingsMgr().tileSize / 2, MapsforgeSettingsMgr().tileSize / 2));
    Map<Tile, double> tileMap = <Tile, double>{};
    for (int tileY = tileDimension.top; tileY <= tileDimension.bottom; ++tileY) {
      for (int tileX = tileDimension.left; tileX <= tileDimension.right; ++tileX) {
        Tile tile = Tile(tileX, tileY, zoomLevel, indoorLevel);
        Mappoint leftUpper = tile.getLeftUpper();
        // Replace pow() with multiplication for better performance
        double dx = leftUpper.x - relative.dx;
        double dy = leftUpper.y - relative.dy;
        tileMap[tile] = dx * dx + dy * dy;
      }
    }
    //_log.info("$tileTop, $tileBottom, sort ${tileMap.length} items");

    List<Tile> sortedKeys = tileMap.keys.toList(growable: false)..sort((k1, k2) => tileMap[k1]!.compareTo(tileMap[k2]!));

    return sortedKeys;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _CurrentJob {
  final MapPosition position;

  final TileDimension tileDimension;

  final TileSet tileSet;

  bool _done = false;

  bool _abort = false;

  _CurrentJob(this.position, this.tileDimension, this.tileSet);

  void abort() => _abort = true;
}
