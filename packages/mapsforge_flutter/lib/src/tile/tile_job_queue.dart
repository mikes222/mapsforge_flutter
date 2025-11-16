import 'dart:async';

import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/tile/tile_dimension.dart';
import 'package:mapsforge_flutter/src/tile/tile_set.dart';
import 'package:mapsforge_flutter/src/util/tile_helper.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:rxdart/rxdart.dart';

// todo we need a method to invalidate the tileset
class TileJobQueue {
  final MapModel mapModel;

  MapSize? _size;

  final _cache = LruCache<Tile, TilePicture?>(
    onEvict: (tile, picture) {
      picture?.dispose();
    },
    capacity: 2000,
    name: "TileJobQueue",
  );

  static _CurrentJob? _currentJob;

  StreamSubscription<MapPosition>? _subscription;

  final Subject<TileSet> _tileStream = PublishSubject<TileSet>();

  /// Parallel task queue for tile loading optimization
  late final TaskQueue _taskQueue;

  /// Maximum number of concurrent tile loading operations
  static const int _maxConcurrentTiles = 4;

  TileJobQueue({required this.mapModel}) {
    _taskQueue = ParallelTaskQueue(_maxConcurrentTiles);

    _subscription = mapModel.positionStream.listen((MapPosition position) {
      if (_currentJob?.tileSet.mapPosition == position) {
        return;
      }
      if (_currentJob?.tileSet.mapPosition.latitude == position.latitude &&
          _currentJob?.tileSet.mapPosition.longitude == position.longitude &&
          _currentJob?.tileSet.mapPosition.zoomlevel == position.zoomlevel &&
          _currentJob?.tileSet.mapPosition.indoorLevel == position.indoorLevel) {
        // do not recalculate for rotation or scaling
        TileSet tileSet = TileSet(center: _currentJob!.tileSet.center, mapPosition: position);
        tileSet.images.addEntries(_currentJob!.tileSet.images.entries);
        _CurrentJob myJob = _CurrentJob(_currentJob!.tileDimension, tileSet);
        _currentJob = myJob;
        _emitTileSetBatched(_currentJob!.tileSet);
        return;
      }
      TileDimension tileDimension = TileHelper.calculateTiles(mapViewPosition: position, screensize: _size!);
      // if (_currentJob?.tileDimension.contains(tileDimension) ?? false) {
      //   if (_currentJob!._done) {
      //     _emitTileSetBatched(_currentJob!.tileSet);
      //   } else {
      //     // same information to draw, previous job is still running, but we have to update the position anyway
      //     _emitTileSetBatched(_currentJob!.tileSet);
      //     return;
      //   }
      // }
      _currentJob?.abort();
      unawaited(
        _positionEvent(position, tileDimension).catchError((error) {
          print(error);
        }),
      );
    });
  }

  void dispose() {
    _currentJob?.abort();
    _subscription?.cancel();
    _taskQueue.cancel();
    _tileStream.close();
    _cache.dispose();
  }

  /// Sets the current size of the mapview so that we know which and how many tiles we need for the whole view
  void setSize(double width, double height) {
    if (_size == null || _size!.width != width || _size!.height != height) {
      _size = MapSize(width: width, height: height);
      if (mapModel.lastPosition != null) {
        TileDimension tileDimension = TileHelper.calculateTiles(mapViewPosition: mapModel.lastPosition!, screensize: _size!);
        _currentJob?.abort();
        unawaited(
          _positionEvent(mapModel.lastPosition!, tileDimension).catchError((error) {
            print(error);
          }),
        );
      }
      return;
    }
    _size = MapSize(width: width, height: height);
  }

  MapSize? getSize() => _size;

  Future<void> _positionEvent(MapPosition position, TileDimension tileDimension) async {
    final session = PerformanceProfiler().startSession(category: "TileJobQueue");
    TileSet tileSet = TileSet(center: position.getCenter(), mapPosition: position);
    _CurrentJob myJob = _CurrentJob(tileDimension, tileSet);
    _currentJob = myJob;
    List<Tile> tiles = _createTiles(mapPosition: position, tileDimension: tileDimension);
    List<Tile> missingTiles = [];

    // retrieve all available tiles from cache
    for (Tile tile in tiles) {
      try {
        TilePicture? picture = _cache.get(tile);
        if (picture != null) {
          tileSet.images[tile] = picture;
        } else {
          missingTiles.add(tile);
        }
      } catch (error) {
        // previous tile generation not yet done or another error occured, check in the second pass
        missingTiles.add(tile);
      }
    }
    if (myJob._abort) return;
    if (tileSet.images.isNotEmpty) {
      /// send the available tiles to ui with batching
      _emitTileSetBatched(tileSet);
    }

    for (Tile tile in missingTiles) {
      unawaited(_taskQueue.add(() => _producePicture(myJob, tileSet, tile)));
    }
    unawaited(
      _taskQueue.add(() async {
        myJob._done = true;
      }),
    );
    session.complete();
  }

  Future<void> _producePicture(_CurrentJob myJob, TileSet tileSet, Tile tile) async {
    if (myJob._abort) return;
    TilePicture? picture = await _cache.getOrProduce(tile, (Tile tile) async {
      try {
        JobResult result = await mapModel.renderer.executeJob(JobRequest(tile));
        if (result.picture == null) {
          return null;
          // print("No picture for tile $tile");
          // return ImageHelper().createNoDataBitmap();
        }
        // make sure the picture is converted to an image
        await result.picture!.convertPictureToImage();
        return result.picture!;
      } catch (error, stacktrace) {
        // error in ecache abort() method. The completer should be checked for isComplete() before injecting an exception
        print(error);
        print(stacktrace);
        rethrow;
      }
    });
    if (myJob._abort) return;
    if (picture != null) {
      tileSet.images[tile] = picture;
    } else {
      tileSet.images[tile] = await ImageHelper().createNoDataBitmap();
    }
    _emitTileSetBatched(tileSet);
  }

  Stream<TileSet> get tileStream => _tileStream.stream.throttleTime(const Duration(milliseconds: 16), trailing: true, leading: false);

  /// Emit tile set with batching to reduce stream emissions
  void _emitTileSetBatched(TileSet tileSet) {
    _tileStream.add(tileSet);
    // _batchTileset = tileSet;
    // // Set new timer for batching
    // _batchTimer ??= Timer(const Duration(milliseconds: 16), () {
    //   // ~60fps
    //   _batchTimer = null;
    //   if (_batchTileset != null && !_tileStream.isClosed) {
    //     _tileStream.add(_batchTileset!);
    //   }
    // });
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
    MappointRelative relative = center.offset(Mappoint(MapsforgeSettingsMgr().tileSize / 2, MapsforgeSettingsMgr().tileSize / 2));
    Map<Tile, double> tileMap = <Tile, double>{};
    for (int tileY = tileDimension.minTop; tileY <= tileDimension.minBottom; ++tileY) {
      for (int tileX = tileDimension.minLeft; tileX <= tileDimension.minRight; ++tileX) {
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

    for (int tileY = tileDimension.top; tileY <= tileDimension.bottom; ++tileY) {
      for (int tileX = tileDimension.left; tileX <= tileDimension.right; ++tileX) {
        if (tileX >= tileDimension.minLeft && tileX <= tileDimension.minRight && tileY >= tileDimension.minTop && tileY <= tileDimension.minBottom) continue;
        Tile tile = Tile(tileX, tileY, zoomLevel, indoorLevel);
        sortedKeys.add(tile);
      }
    }

    return sortedKeys;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _CurrentJob {
  final TileDimension tileDimension;

  final TileSet tileSet;

  bool _done = false;

  bool _abort = false;

  _CurrentJob(this.tileDimension, this.tileSet);

  void abort() => _abort = true;
}
