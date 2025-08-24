import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/cache/tile_cache.dart';
import 'package:mapsforge_view/src/tile_dimension.dart';
import 'package:mapsforge_view/src/tile_set.dart';
import 'package:rxdart/rxdart.dart';

import 'cache/memory_tile_cache.dart';

class TileJobQueue {
  final MapModel mapsforgeModel;

  MapSize? _size;

  TileCache tileCache = MemoryTileCache.create();

  static _CurrentJob? _currentJob;

  StreamSubscription<MapPosition>? _subscription;

  final Subject<TileSet> _tileStream = PublishSubject<TileSet>();

  TileJobQueue({required this.mapsforgeModel}) {
    _subscription = mapsforgeModel.positionStream.listen((MapPosition position) {
      if (_currentJob != null &&
          _currentJob!.position.indoorLevel == position.indoorLevel &&
          _currentJob!.position.zoomLevel == position.zoomLevel &&
          _currentJob!.position.getCenter() == position.getCenter()) {
        return;
      }
      _currentJob?.abort();
      // unawaited
      _positionEvent(position);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _tileStream.close();
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
    List<Tile> tiles = _createTiles(mapPosition: position, tileDimension: tileDimension);

    TileSet tileSet = TileSet(center: position.getCenter(), mapPosition: position);
    for (Tile tile in tiles) {
      TilePicture? picture = await tileCache.getOrProduce(tile, (Tile tile) async {
        JobResult result = await mapsforgeModel.renderer.executeJob(JobRequest(tile));
        if (result.picture == null) return ImageHelper().createNoDataBitmap();
        // make sure the picture is converted to an image
        Image image = await result.picture!.convertPictureToImage();
        return result.picture!;
      });
      if (myJob._abort) return;
      if (picture != null) {
        tileSet.images[tile] = JobResult.normal(picture);
        _tileStream.add(tileSet);
        continue;
      }
    }
  }

  Stream<TileSet> get tileStream => _tileStream.stream;

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

  ///
  /// Get all tiles needed for a given view. The tiles are in the order where it makes most sense for
  /// the user (tile in the middle should be created first
  ///
  List<Tile> _createTiles({required MapPosition mapPosition, required TileDimension tileDimension}) {
    int zoomLevel = mapPosition.zoomLevel;
    int indoorLevel = mapPosition.indoorLevel;
    Mappoint center = mapPosition.getCenter();
    // shift the center to the left-upper corner of a tile since we will calculate the distance to the left-upper corners of each tile
    RelativeMappoint relative = center.offset(Mappoint(MapsforgeSettingsMgr().tileSize / 2, MapsforgeSettingsMgr().tileSize / 2));
    Map<Tile, double> tileMap = <Tile, double>{};
    for (int tileY = tileDimension.top; tileY <= tileDimension.bottom; ++tileY) {
      for (int tileX = tileDimension.left; tileX <= tileDimension.right; ++tileX) {
        Tile tile = Tile(tileX, tileY, zoomLevel, indoorLevel);
        Mappoint leftUpper = tile.getLeftUpper();
        tileMap[tile] = (pow(leftUpper.x - relative.dx, 2) + pow(leftUpper.y - relative.dy, 2)).toDouble();
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

  bool _abort = false;

  _CurrentJob(this.position);

  void abort() => _abort = true;
}
