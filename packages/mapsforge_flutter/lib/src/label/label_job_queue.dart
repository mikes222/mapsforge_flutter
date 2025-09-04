import 'dart:async';
import 'dart:math';

import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/cache/memory_label_cache.dart';
import 'package:mapsforge_flutter/src/label/label_set.dart';
import 'package:mapsforge_flutter/src/tile/tile_dimension.dart';
import 'package:mapsforge_flutter/src/util/tile_helper.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:rxdart/rxdart.dart';

class LabelJobQueue {
  final MapModel mapModel;

  MapSize? _size;

  final MemoryLabelCache _cache = MemoryLabelCache.create();

  static _CurrentJob? _currentJob;

  StreamSubscription<MapPosition>? _subscription;

  /// We split the labels into a 5 by 5 tiles matrix and retrieve the labels for these 25 tiles at once.
  final int _range = 5;

  final Subject<LabelSet> _labelStream = PublishSubject<LabelSet>();

  LabelJobQueue({required this.mapModel}) {
    _subscription = mapModel.positionStream.listen((MapPosition position) {
      if (_currentJob?.position == position) {
        return;
      }
      TileDimension tileDimension = TileHelper.calculateTiles(mapViewPosition: position, screensize: _size!);
      if (_currentJob?.tileDimension.contains(tileDimension) ?? false) {
        if (_currentJob!._done) {
          _labelStream.add(_currentJob!.labelSet);
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
    _subscription?.cancel();
    _labelStream.close();
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
    // stop if we do not yet have a size of the view
    if (_size == null) return;
    LabelSet labelSet = LabelSet(center: position.getCenter(), mapPosition: position, renderInfos: []);
    _CurrentJob myJob = _CurrentJob(position, tileDimension, labelSet);
    _currentJob = myJob;
    int left = tileDimension.left;
    int top = tileDimension.top;
    // find a common base (multiplies of 5) to start with
    left = (left / _range).floor() * _range;
    top = (top / _range).floor() * _range;
    int maxTileNbr = Tile.getMaxTileNumber(position.zoomlevel);
    while (true) {
      while (true) {
        Tile leftUpper = Tile(left, top, position.zoomlevel, position.indoorLevel);
        Tile rightLower = Tile(min(left + _range - 1, maxTileNbr), min(top + _range - 1, maxTileNbr), position.zoomlevel, position.indoorLevel);
        RenderInfoCollection collection = await _cache.getOrProduce(leftUpper, rightLower, (Tile tile) async {
          JobResult result = await mapModel.renderer.retrieveLabels(JobRequest(leftUpper, rightLower));
          if (result.renderInfo == null) throw Exception("No renderInfo for $tile");
          return result.renderInfo!;
        });
        if (myJob._abort) return;
        labelSet.renderInfos.add(collection);
        _labelStream.add(labelSet);
        left += _range;
        if (left > tileDimension.right) break;
      }
      top += _range;
      left = (tileDimension.left / _range).floor() * _range;
      if (top > tileDimension.bottom) break;
    }
    myJob._done = true;
  }

  Stream<LabelSet> get labelStream => _labelStream.stream;
}

//////////////////////////////////////////////////////////////////////////////

class _CurrentJob {
  final MapPosition position;

  final TileDimension tileDimension;

  final LabelSet labelSet;

  bool _done = false;

  bool _abort = false;

  _CurrentJob(this.position, this.tileDimension, this.labelSet);

  void abort() => _abort = true;
}
