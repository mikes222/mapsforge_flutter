import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import '../model/tile.dart';

import 'mapdatastore.dart';
import 'datastorereadresult.dart';

/// A MapDatabase that reads and combines data from multiple map files.
/// The MultiMapDatabase supports the following modes for reading from multiple files:
/// - RETURN_FIRST: the data from the first database to support a tile will be returned. This is the
/// fastest operation suitable when you know there is no overlap between map files.
/// - RETURN_ALL: the data from all files will be returned, the data will be combined. This is suitable
/// if more than one file can contain data for a tile, but you know there is no semantic overlap, e.g.
/// one file contains contour lines, another road data.
/// - DEDUPLICATE: the data from all files will be returned but duplicates will be eliminated. This is
/// suitable when multiple maps cover the different areas, but there is some overlap at boundaries. This
/// is the most expensive operation and often it is actually faster to double paint objects as otherwise
/// all objects have to be compared with all others.
class MultiMapDataStore extends MapDataStore {
  static final _log = new Logger('MultiMapDataStore');

  @override
  BoundingBox? boundingBox;
  final DataPolicy dataPolicy;
  final List<MapDataStore> mapDatabases;
  @override
  LatLong? startPosition;
  @override
  int? startZoomLevel;

  MultiMapDataStore(this.dataPolicy)
      : mapDatabases = [],
        super(null);

  /// adds another mapDataStore
  ///
  /// @param mapDataStore      the mapDataStore to add
  /// @param useStartZoomLevel if true, use the start zoom level of this mapDataStore as the start zoom level
  /// @param useStartPosition  if true, use the start position of this mapDataStore as the start position
  void addMapDataStore(MapDataStore mapDataStore, bool useStartZoomLevel,
      bool useStartPosition) {
    if (this.mapDatabases.contains(mapDataStore)) {
      throw new Exception("Duplicate map database");
    }
    this.mapDatabases.add(mapDataStore);
    if (useStartZoomLevel) {
      this.startZoomLevel = mapDataStore.startZoomLevel;
    }
    if (useStartPosition) {
      this.startPosition = mapDataStore.startPosition;
    }
    // if (null == this.boundingBox) {
    //   this.boundingBox = mapDataStore.boundingBox;
    // } else {
    //   this.boundingBox =
    //       this.boundingBox!.extendBoundingBox(mapDataStore.boundingBox!);
    // }
  }

  void removeMapDataStore(double minLatitude, double minLongitude,
      double maxLatitude, double maxLongitude) {
    mapDatabases.removeWhere((MapDataStore mapDataStore) {
      if (mapDataStore.boundingBox!.minLatitude == minLatitude &&
          mapDataStore.boundingBox!.maxLatitude == maxLatitude &&
          mapDataStore.boundingBox!.minLongitude == minLongitude &&
          mapDataStore.boundingBox!.maxLongitude == maxLongitude) return true;
      return false;
    });
    if (this.boundingBox != null) {
      // recalc boundingbox
      this.boundingBox = null;
      mapDatabases.forEach((mapDataStore) {
        if (null == this.boundingBox) {
          this.boundingBox = mapDataStore.boundingBox;
        } else {
          this.boundingBox =
              this.boundingBox!.extendBoundingBox(mapDataStore.boundingBox!);
        }
      });
    }
  }

  void removeAllDatastores() {
    this.boundingBox = null;
    startPosition = null;
    startZoomLevel = null;
    this.mapDatabases.clear();
  }

  /// Returns the timestamp of the data used to render a specific tile.
  /// <p/>
  /// If the tile uses data from multiple data stores, the most recent timestamp is returned.
  ///
  /// @param tile A tile.
  /// @return the timestamp of the data used to render the tile
  @override
  int? getDataTimestamp(Tile tile) {
    Projection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile, projection)) {
            return mdb.getDataTimestamp(tile);
          }
        }
        return 0;
      case DataPolicy.RETURN_ALL:
      case DataPolicy.DEDUPLICATE:
        int result = 0;
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile, projection)) {
            result = max(result, mdb.getDataTimestamp(tile)!);
          }
        }
        return result;
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  @override
  Future<DatastoreReadResult?> readLabelsSingle(Tile tile) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        Projection projection =
            MercatorProjection.fromZoomlevel(tile.zoomLevel);
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile, projection)) {
            return mdb.readLabelsSingle(tile);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readLabelsDedup(tile, false);
      case DataPolicy.DEDUPLICATE:
        return _readLabelsDedup(tile, true);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreReadResult> _readLabelsDedup(
      Tile tile, bool deduplicate) async {
    Projection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    DatastoreReadResult mapReadResult =
        DatastoreReadResult(pointOfInterests: [], ways: []);
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(tile, projection)) {
        //_log.info("Tile ${tile.toString()} is supported by ${mdb.toString()}");
        DatastoreReadResult? result = await mdb.readLabelsSingle(tile);
        if (result == null) {
          continue;
        }
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    return mapReadResult;
  }

  @override
  Future<DatastoreReadResult?> readLabels(
      Tile upperLeft, Tile lowerRight) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        Projection projection =
            MercatorProjection.fromZoomlevel(upperLeft.zoomLevel);
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(upperLeft, projection)) {
            return mdb.readLabels(upperLeft, lowerRight);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readLabels(upperLeft, lowerRight, false);
      case DataPolicy.DEDUPLICATE:
        return _readLabels(upperLeft, lowerRight, true);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreReadResult> _readLabels(
      Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    DatastoreReadResult mapReadResult =
        new DatastoreReadResult(pointOfInterests: [], ways: []);
    Projection projection =
        MercatorProjection.fromZoomlevel(upperLeft.zoomLevel);
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(upperLeft, projection)) {
        DatastoreReadResult? result =
            await mdb.readLabels(upperLeft, lowerRight);
        if (result == null) {
          continue;
        }
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    return mapReadResult;
  }

  @override
  Future<DatastoreReadResult?> readMapDataSingle(Tile tile) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        Projection projection =
            MercatorProjection.fromZoomlevel(tile.zoomLevel);
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile, projection)) {
            return mdb.readMapDataSingle(tile);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readMapData(tile, false);
      case DataPolicy.DEDUPLICATE:
        return _readMapData(tile, true);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreReadResult?> _readMapData(Tile tile, bool deduplicate) async {
    DatastoreReadResult mapReadResult =
        new DatastoreReadResult(pointOfInterests: [], ways: []);
    bool found = false;
    Projection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    for (MapDataStore mdb in List.of(mapDatabases)) {
      if (mdb.supportsTile(tile, projection)) {
        //_log.info("Tile2 ${tile.toString()} is supported by ${mdb.toString()}");
        try {
          DatastoreReadResult? result = await mdb.readMapDataSingle(tile);
          if (result == null) {
            continue;
          }
          found = true;
          bool isWater = mapReadResult.isWater & result.isWater;
          mapReadResult.isWater = isWater;
          mapReadResult.addDeduplicate(result, deduplicate);
        } on FileNotFoundException catch (error) {
          _log.warning("File ${error.filename} missing, removing mapfile now");
          mapDatabases.remove(mdb);
        }
      }
    }
    if (!found) return null;
    return mapReadResult;
  }

  @override
  Future<DatastoreReadResult?> readMapData(
      Tile upperLeft, Tile lowerRight) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        Projection projection =
            MercatorProjection.fromZoomlevel(upperLeft.zoomLevel);
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(upperLeft, projection)) {
            return mdb.readMapData(upperLeft, lowerRight);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readMapDataDedup(upperLeft, lowerRight, false);
      case DataPolicy.DEDUPLICATE:
        return _readMapDataDedup(upperLeft, lowerRight, true);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreReadResult?> _readMapDataDedup(
      Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    DatastoreReadResult mapReadResult =
        new DatastoreReadResult(pointOfInterests: [], ways: []);
    bool found = false;
    Projection projection =
        MercatorProjection.fromZoomlevel(upperLeft.zoomLevel);
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(upperLeft, projection)) {
        //_log.info("Tile3 ${upperLeft.toString()} is supported by ${mdb.toString()}");
        DatastoreReadResult? result =
            await mdb.readMapData(upperLeft, lowerRight);
        if (result == null) {
          continue;
        }
        found = true;
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    if (!found) return null;
    return mapReadResult;
  }

  @override
  Future<DatastoreReadResult?> readPoiDataSingle(Tile tile) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        Projection projection =
            MercatorProjection.fromZoomlevel(tile.zoomLevel);
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile, projection)) {
            return mdb.readPoiDataSingle(tile);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readPoiData(tile, false);
      case DataPolicy.DEDUPLICATE:
        return _readPoiData(tile, true);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreReadResult> _readPoiData(Tile tile, bool deduplicate) async {
    DatastoreReadResult mapReadResult =
        new DatastoreReadResult(pointOfInterests: [], ways: []);
    Projection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(tile, projection)) {
        DatastoreReadResult? result = await mdb.readPoiDataSingle(tile);
        if (result == null) {
          continue;
        }
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    return mapReadResult;
  }

  @override
  Future<DatastoreReadResult?> readPoiData(
      Tile upperLeft, Tile lowerRight) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        Projection projection =
            MercatorProjection.fromZoomlevel(upperLeft.zoomLevel);
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(upperLeft, projection)) {
            return mdb.readPoiData(upperLeft, lowerRight);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readPoiDataDedup(upperLeft, lowerRight, false);
      case DataPolicy.DEDUPLICATE:
        return _readPoiDataDedup(upperLeft, lowerRight, true);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreReadResult> _readPoiDataDedup(
      Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    DatastoreReadResult mapReadResult =
        new DatastoreReadResult(pointOfInterests: [], ways: []);
    Projection projection =
        MercatorProjection.fromZoomlevel(upperLeft.zoomLevel);
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(upperLeft, projection)) {
        DatastoreReadResult? result =
            await mdb.readPoiData(upperLeft, lowerRight);
        if (result == null) {
          continue;
        }
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    return mapReadResult;
  }

  void setStartPosition(LatLong startPosition) {
    this.startPosition = startPosition;
  }

  void setStartZoomLevel(int startZoomLevel) {
    this.startZoomLevel = startZoomLevel;
  }

  @override
  bool supportsTile(Tile tile, Projection projection) {
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(tile, projection)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> lateOpen() async {
    for (MapDataStore mdb in mapDatabases) {
      await mdb.lateOpen();
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

enum DataPolicy {
  RETURN_FIRST, // return the first set of data
  RETURN_ALL, // return all data from databases
  DEDUPLICATE // return all data but eliminate duplicates
}
