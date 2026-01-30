import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/cache/memory_label_cache.dart';
import 'package:mapsforge_flutter/src/label/label_set.dart';
import 'package:mapsforge_flutter/src/tile/tile_dimension.dart';
import 'package:mapsforge_flutter/src/util/tile_helper.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

class LabelJobQueue extends ChangeNotifier {
  final MapModel mapModel;

  MapSize? _size;

  final MemoryLabelCache _cache = MemoryLabelCache.create();

  static _CurrentJob? _currentJob;

  late final StreamSubscription<RenderChangedEvent> _renderChangedSubscription;

  /// We split the labels into a 5 by 5 tiles matrix and retrieve the labels for these 25 tiles at once.
  final int _range = 5;

  /// Parallel task queue for tile loading optimization
  late final TaskQueue _taskQueue;

  /// Maximum number of concurrent tile loading operations
  static const int _maxConcurrentTiles = 4;

  final Renderer renderer;

  LabelJobQueue({required this.mapModel, required this.renderer}) {
    _taskQueue = ParallelTaskQueue(_maxConcurrentTiles);

    _renderChangedSubscription = mapModel.renderChangedStream.listen((RenderChangedEvent event) {
      // simple approach, clear all
      _cache.purgeAll();
      _CurrentJob? myJob = _currentJob;
      if (myJob != null) {
        _currentJob?.abort();
        unawaited(
          _positionEvent(myJob.labelSet.mapPosition, myJob.tileDimension).catchError((error) {
            print(error);
          }),
        );
      }
    });
  }

  LabelSet get labelSet => _currentJob!.labelSet;

  void setPosition(MapPosition position) {
    if (_currentJob?.labelSet.mapPosition == position) {
      return;
    }
    if (_currentJob?.labelSet.mapPosition.latitude == position.latitude &&
        _currentJob?.labelSet.mapPosition.longitude == position.longitude &&
        _currentJob?.labelSet.mapPosition.zoomlevel == position.zoomlevel &&
        _currentJob?.labelSet.mapPosition.indoorLevel == position.indoorLevel) {
      // do not recalculate for rotation or scaling
      LabelSet labelSet = LabelSet(center: _currentJob!.labelSet.center, mapPosition: position, renderInfos: _currentJob!.labelSet.renderInfos);
      _CurrentJob myJob = _CurrentJob(_currentJob!.tileDimension, labelSet);
      _currentJob = myJob;
      _emitLabelSetBatched(_currentJob!.labelSet);
      return;
    }
    TileDimension tileDimension = TileHelper.calculateTiles(mapViewPosition: position, screensize: _size!);
    // if (_currentJob?.tileDimension.contains(tileDimension) ?? false) {
    //   if (_currentJob!._done) {
    //     _emitLabelSetBatched(_currentJob!.labelSet);
    //   } else {
    //     // same information to draw, previous job is still running
    //     return;
    //   }
    // }
    _currentJob?.abort();
    unawaited(_positionEvent(position, tileDimension));
  }

  @override
  void dispose() {
    super.dispose();
    _currentJob?.abort();
    _renderChangedSubscription.cancel();
    _cache.dispose();
  }

  /// Sets the current size of the mapview so that we know which and how many tiles we need for the whole view
  void setSize(double width, double height) {
    if (_size == null || _size!.width != width || _size!.height != height) {
      _size = MapSize(width: width, height: height);
      if (mapModel.lastPosition != null) {
        TileDimension tileDimension = TileHelper.calculateTiles(mapViewPosition: mapModel.lastPosition!, screensize: _size!);
        _currentJob?.abort();
        unawaited(_positionEvent(mapModel.lastPosition!, tileDimension));
      }
      return;
    }
    _size = MapSize(width: width, height: height);
  }

  MapSize? getSize() => _size;

  Future<void> _positionEvent(MapPosition position, TileDimension tileDimension) async {
    final session = PerformanceProfiler().startSession(category: "LabelJobQueue");
    LabelSet labelSet = LabelSet(center: position.getCenter(), mapPosition: position, renderInfos: []);
    _CurrentJob myJob = _CurrentJob(tileDimension, labelSet);
    _currentJob = myJob;
    // find a common base (multiplies of 5) to start with
    int maxTileNbr = Tile.getMaxTileNumber(position.zoomlevel);
    List<Tile> missingTiles = [];
    for (int top = (tileDimension.top / _range).floor() * _range; top <= tileDimension.bottom; top += _range) {
      for (int left = (tileDimension.left / _range).floor() * _range; left <= tileDimension.right; left += _range) {
        Tile leftUpper = Tile(left, top, position.zoomlevel, position.indoorLevel);
        try {
          RenderInfoCollection? collection = _cache.get(leftUpper);
          if (collection != null) {
            labelSet.renderInfos.add(collection);
          } else {
            missingTiles.add(leftUpper);
          }
        } catch (e) {
          missingTiles.add(leftUpper);
        }
      }
    }
    if (myJob._abort) return;
    if (labelSet.renderInfos.isNotEmpty) {
      _emitLabelSetBatched(labelSet);
    }
    for (Tile tile in missingTiles) {
      unawaited(_taskQueue.add(() => _produceLabel(myJob, labelSet, tile.tileX, tile.tileY, position, maxTileNbr)));
    }
    unawaited(
      _taskQueue.add(() async {
        myJob._done = true;
      }),
    );
    session.complete();
  }

  Future<void> _produceLabel(_CurrentJob myJob, LabelSet labelSet, int left, int top, MapPosition position, int maxTileNbr) async {
    if (myJob._abort) return;
    Tile leftUpper = Tile(left, top, position.zoomlevel, position.indoorLevel);
    Tile rightLower = Tile(min(left + _range - 1, maxTileNbr), min(top + _range - 1, maxTileNbr), position.zoomlevel, position.indoorLevel);
    RenderInfoCollection collection = await _cache.getOrProduce(leftUpper, rightLower, (Tile tile) async {
      JobResult result = await renderer.retrieveLabels(JobRequest(leftUpper, rightLower));
      if (result.renderInfo == null) throw Exception("No renderInfo for $tile from renderer ${renderer.getRenderKey()}");
      return result.renderInfo!;
    });
    if (myJob._abort) return;
    labelSet.renderInfos.add(collection);
    _emitLabelSetBatched(labelSet);
  }

  /// Emit tile set with batching to reduce stream emissions
  void _emitLabelSetBatched(LabelSet labelSet) {
    notifyListeners();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _CurrentJob {
  final TileDimension tileDimension;

  final LabelSet labelSet;

  bool _done = false;

  bool _abort = false;

  _CurrentJob(this.tileDimension, this.labelSet);

  void abort() => _abort = true;
}
