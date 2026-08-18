import 'dart:async';
import 'dart:math';

import 'package:ecache/ecache.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/tile/tile_dimension.dart';
import 'package:mapsforge_flutter/src/tile/tile_set.dart';
import 'package:mapsforge_flutter/src/util/tile_helper.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';

/// The jobqueue for a tile. It gets informed if the size of the view changes with [setSize] and if the
/// position of the map changes [setPosition]. Based on these informations the tiles will be prepared
/// and the painter will be triggered with [notifyListeners] as soon as tiles are available.
class TileJobQueue extends ChangeNotifier {
  final MapModel mapModel;

  MapSize? _size;

  final Renderer renderer;

  final _cache = LruCache<Tile, TilePicture?>(
    onEvict: (tile, picture) {
      picture?.dispose();
    },
    capacity: 2000,
    name: "TileJobQueue",
  );

  _CurrentJob? _currentJob;

  /// subscribe to renderChanged events which are triggered when the underlying renderdata has
  /// been changed, e.g. if a map has been added to a multimap. This should force a revalidation of the cache and
  /// a redraw of the backed view.
  late final StreamSubscription<RenderChangedEvent> _renderChangedSubscription;

  /// Parallel task queue for tile loading optimization
  late final TaskQueue _taskQueue;

  /// Maximum number of concurrent tile loading operations
  static const int _maxConcurrentTiles = 4;

  TileJobQueue({required this.mapModel, required this.renderer}) {
    _taskQueue = ParallelTaskQueue(_maxConcurrentTiles);

    _renderChangedSubscription = mapModel.renderChangedStream.listen((RenderChangedEvent event) {
      // simple approach, clear all
      _cache.clear();
      _CurrentJob? myJob = _currentJob;
      if (myJob != null) {
        _currentJob?.abort();
        unawaited(
          _positionEvent(myJob.tileSet.mapPosition, myJob.tileDimension).catchError((error) {
            print(error);
          }),
        );
      }
    });
  }

  void setPosition(MapPosition position) {
    //print("Position change $position for renderer ${renderer.getRenderKey()} ${_currentJob?.tileSet.mapPosition == position}");
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
  }

  @override
  void dispose() {
    super.dispose();
    _currentJob?.abort();
    _renderChangedSubscription.cancel();
    // remove all jobs without throwing exceptions
    _taskQueue.clear();
    _taskQueue.cancel();
    _cache.dispose();
  }

  TileSet? get tileSet => _currentJob?.tileSet;

  /// Sets the current size of the mapview so that we know which and how many tiles we need for the whole view
  void setSize(double width, double height) {
    if (_size == null || _size!.width != width || _size!.height != height) {
      _size = MapSize(width: width, height: height);
      MapPosition? position = _currentJob?.tileSet.mapPosition;
      if (position != null) {
        TileDimension tileDimension = TileHelper.calculateTiles(mapViewPosition: position, screensize: _size!);
        _currentJob?.abort();
        unawaited(
          _positionEvent(position, tileDimension).catchError((error) {
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
    try {
      TilePicture? picture = await _cache.getOrProduce(tile, (Tile tile) async {
        try {
          JobResult result = await renderer.executeJob(JobRequest(tile));
          if (result.picture == null) {
            //return null;
            // print("No picture for tile $tile");
            return ImageHelper().createNoDataBitmap();
          }
          // make sure the picture is converted to an image because rendering (vector) pictures is usually slower than drawing images
          result.picture!.convertPictureToImage();
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
        //print("Added picture for tile $tile for renderer ${renderer.getRenderKey()}");
      } else {
        tileSet.images[tile] = await ImageHelper().createNoDataBitmap();
      }
      _emitTileSetBatched(tileSet);
    } on TimeoutException catch (error, stackTrace) {
      // we aborted the job, ignore this error
    }
  }

  /// Emit tile set with batching to reduce stream emissions
  void _emitTileSetBatched(TileSet tileSet) {
    notifyListeners();
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
    final int zoomLevel = mapPosition.zoomlevel;
    final int indoorLevel = mapPosition.indoorLevel;
    final Mappoint center = mapPosition.getCenter();
    final double tileSize = MapsforgeSettingsMgr().tileSize;
    final double halfTileSize = tileSize / 2;
    // shift the center to the left-upper corner of a tile since we will calculate the distance to the left-upper corners of each tile
    final MappointRelative relative = MappointRelative(center.x - halfTileSize, center.y - halfTileSize);

    final int startX = min(tileDimension.minLeft, tileDimension.left);
    final int endX = max(tileDimension.minRight, tileDimension.right);
    final int startY = min(tileDimension.minTop, tileDimension.top);
    final int endY = max(tileDimension.minBottom, tileDimension.bottom);

    final int totalTiles = (endX - startX + 1) * (endY - startY + 1);
    if (totalTiles <= 0) {
      return const [];
    }

    // Pre-size the working list and the final result to avoid repeated resizing.
    final List<_TileDistance> entries = List<_TileDistance>.filled(totalTiles, _TileDistance(Tile(0, 0, 0, 0), 0.0));
    int index = 0;
    for (int tileY = startY; tileY <= endY; ++tileY) {
      final double leftUpperY = tileY * tileSize;
      for (int tileX = startX; tileX <= endX; ++tileX) {
        final double leftUpperX = tileX * tileSize;
        final double dx = leftUpperX - relative.dx;
        final double dy = leftUpperY - relative.dy;
        entries[index++] = _TileDistance(Tile(tileX, tileY, zoomLevel, indoorLevel), dx * dx + dy * dy);
      }
    }

    entries.sort((a, b) => a.distance.compareTo(b.distance));

    return List<Tile>.generate(totalTiles, (i) => entries[i].tile, growable: false);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _TileDistance {
  final Tile tile;
  final double distance;

  _TileDistance(this.tile, this.distance);
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
