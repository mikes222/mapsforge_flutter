import 'dart:async';
import 'dart:math';

import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/cache/memory_label_cache.dart';
import 'package:mapsforge_view/src/label_set.dart';
import 'package:mapsforge_view/src/tile_dimension.dart';
import 'package:rxdart/rxdart.dart';

class LabelJobQueue {
  final MapModel mapsforgeModel;

  MapSize? _size;

  final MemoryLabelCache _cache = MemoryLabelCache.create();

  static _CurrentJob? _currentJob;

  StreamSubscription<MapPosition>? _subscription;

  /// We split the labels into a 5 by 5 tiles matrix and retrieve the labels for these 25 tiles at once.
  final int _range = 5;

  final Subject<LabelSet> _labelStream = PublishSubject<LabelSet>();

  LabelJobQueue({required this.mapsforgeModel}) {
    _subscription = mapsforgeModel.positionStream.listen((MapPosition position) {
      if (_currentJob != null &&
          _currentJob!.position.indoorLevel == position.indoorLevel &&
          _currentJob!.position.zoomLevel == position.zoomLevel &&
          _currentJob!.position.getCenter() == position.getCenter() &&
          _currentJob!.position.rotation == position.rotation) {
        return;
      }
      _currentJob?.abort();
      // unawaited
      _positionEvent(position);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _labelStream.close();
  }

  /// Sets the current size of the mapview so that we know which and how many tiles we need for the whole view
  void setSize(double width, double height) {
    _size = MapSize(width: width, height: height);
  }

  MapSize? getSize() => _size;

  Future<void> _positionEvent(MapPosition position) async {
    // stop if we do not yet have a size of the view
    if (_size == null) return;
    _CurrentJob myJob = _CurrentJob(position);
    _currentJob = myJob;
    TileDimension tileDimension = _calculateTiles(mapViewPosition: position, screensize: _size!);
    int left = tileDimension.left;
    left = (left / _range).floor() * _range;
    int top = tileDimension.top;
    top = (top / _range).floor() * _range;
    LabelSet labelSet = LabelSet(center: position.getCenter(), mapPosition: position, renderInfos: []);
    while (true) {
      while (true) {
        Tile leftUpper = Tile(left, top, position.zoomLevel, position.indoorLevel);
        Tile rightLower = Tile(left + _range - 1, top + _range - 1, position.zoomLevel, position.indoorLevel);
        RenderInfoCollection? collection = await _cache.getOrProduce(leftUpper, rightLower, (String key) async {
          JobResult result = await mapsforgeModel.renderer.retrieveLabels(JobRequest(leftUpper, rightLower));
          if (result.renderInfo == null) throw Exception("No renderInfo for $key");
          return result.renderInfo!;
        });
        if (myJob._abort) return;
        if (collection != null) {
          labelSet.renderInfos.add(collection);
          _labelStream.add(labelSet);
        }
        left += _range;
        if (left + _range - 1 > tileDimension.right) break;
      }
      top += _range;
      if (top + _range - 1 > tileDimension.bottom) break;
    }
  }

  Stream<LabelSet> get labelStream => _labelStream.stream;

  /// Calculates all tiles needed to display the map on the available view area
  TileDimension _calculateTiles({required MapPosition mapViewPosition, required MapSize screensize}) {
    Mappoint center = mapViewPosition.getCenter();
    double halfWidth = screensize.width / 2;
    double halfHeight = screensize.height / 2;
    if (mapViewPosition.rotation > 2) {
      // we rotate. Use the max side for both width and height
      halfWidth = max(halfWidth, halfHeight);
      halfHeight = halfWidth;
    }
    int tileLeft = mapViewPosition.projection.pixelXToTileX(max(center.x - halfWidth, 0));
    int tileRight = mapViewPosition.projection.pixelXToTileX(min(center.x + halfWidth, mapViewPosition.projection.mapsize.toDouble()));
    int tileTop = mapViewPosition.projection.pixelYToTileY(max(center.y - halfHeight, 0));
    int tileBottom = mapViewPosition.projection.pixelYToTileY(min(center.y + halfHeight, mapViewPosition.projection.mapsize.toDouble()));
    // rising from 0 to 45, then falling to 0 at 90°
    int degreeDiff = 45 - ((mapViewPosition.rotation) % 90 - 45).round().abs();
    if (degreeDiff > 5) {
      // the map is rotated. To avoid empty corners enhance each side by one tile
      int diff = (MapsforgeSettingsMgr().getDeviceScaleFactor().ceil());
      tileLeft = max(tileLeft - diff, 0);
      tileRight = min(tileRight + diff, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
      tileTop = max(tileTop - diff, 0);
      tileBottom = min(tileBottom + diff, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
    }
    return TileDimension(left: tileLeft, right: tileRight, top: tileTop, bottom: tileBottom);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _CurrentJob {
  final MapPosition position;

  bool _abort = false;

  _CurrentJob(this.position);

  void abort() => _abort = true;
}
