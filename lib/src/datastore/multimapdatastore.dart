import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';

import '../../datastore.dart';

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

  BoundingBox? boundingBox;
  final DataPolicy dataPolicy;
  final List<Datastore> mapDatabases;

  LatLong? startPosition;

  int? startZoomLevel;

  MultiMapDataStore(this.dataPolicy)
      : mapDatabases = [],
        super(null);

  @override
  void dispose() {
    mapDatabases.forEach((db) => db.dispose());
  }

  /// adds another mapDataStore
  ///
  /// @param mapDataStore      the mapDataStore to add
  /// @param useStartZoomLevel if true, use the start zoom level of this mapDataStore as the start zoom level
  /// @param useStartPosition  if true, use the start position of this mapDataStore as the start position
  Future<void> addMapDataStore(Datastore mapDataStore, bool useStartZoomLevel, bool useStartPosition) async {
    if (this.mapDatabases.contains(mapDataStore)) {
      throw new Exception("Duplicate map database");
    }
    this.mapDatabases.add(mapDataStore);
    if (mapDataStore is MapDataStore) {
      if (useStartZoomLevel) {
        this.startZoomLevel = await mapDataStore.getStartZoomLevel();
      }
      if (useStartPosition) {
        this.startPosition = await mapDataStore.getStartPosition();
      }
    }
    // if (null == this.boundingBox) {
    //   this.boundingBox = mapDataStore.boundingBox;
    // } else {
    //   this.boundingBox =
    //       this.boundingBox!.extendBoundingBox(mapDataStore.boundingBox!);
    // }
  }

  Future<void> removeMapDataStore(double minLatitude, double minLongitude, double maxLatitude, double maxLongitude) async {
    BoundingBox toRemove = BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
    this.boundingBox = null;
    for (Datastore datastore in List.from(mapDatabases)) {
      BoundingBox boundingBox = await datastore.getBoundingBox();
      if (toRemove.intersects(boundingBox)) {
        mapDatabases.remove(datastore);
      } else {
        if (null == this.boundingBox) {
          this.boundingBox = boundingBox;
        } else {
          this.boundingBox = this.boundingBox!.extendBoundingBox(boundingBox);
        }
      }
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
  Future<int?> getDataTimestamp(Tile tile) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in mapDatabases) {
          if (mdb is MapDataStore && (await mdb.supportsTile(tile))) {
            return mdb.getDataTimestamp(tile);
          }
        }
        return 0;
      case DataPolicy.RETURN_ALL:
      case DataPolicy.DEDUPLICATE:
        int result = 0;
        for (Datastore mdb in mapDatabases) {
          if (mdb is MapDataStore && (await mdb.supportsTile(tile))) {
            result = max(result, (await mdb.getDataTimestamp(tile))!);
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
        for (Datastore mdb in mapDatabases) {
          if ((await mdb.supportsTile(tile))) {
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

  Future<DatastoreReadResult> _readLabelsDedup(Tile tile, bool deduplicate) async {
    DatastoreReadResult mapReadResult = DatastoreReadResult(pointOfInterests: [], ways: []);
    List<Future<DatastoreReadResult?>> futures = [];
    for (Datastore mdb in List.from(mapDatabases)) {
      futures.add(() async {
        if ((await mdb.supportsTile(tile))) {
          //_log.info("Tile ${tile.toString()} is supported by ${mdb.toString()}");
          DatastoreReadResult? result = await mdb.readLabelsSingle(tile);
          return result;
        }
        return null;
      }());
    }
    List<DatastoreReadResult?> results = await Future.wait(futures);
    results.forEach((result) {
      if (result == null) {
        return;
      }
      bool isWater = mapReadResult.isWater & result.isWater;
      mapReadResult.isWater = isWater;
      mapReadResult.addDeduplicate(result, deduplicate);
    });
    return mapReadResult;
  }

  @override
  Future<DatastoreReadResult?> readLabels(Tile upperLeft, Tile lowerRight) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in mapDatabases) {
          if ((await mdb.supportsTile(upperLeft))) {
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

  Future<DatastoreReadResult> _readLabels(Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    DatastoreReadResult mapReadResult = new DatastoreReadResult(pointOfInterests: [], ways: []);
    for (Datastore mdb in mapDatabases) {
      if ((await mdb.supportsTile(upperLeft))) {
        DatastoreReadResult? result = await mdb.readLabels(upperLeft, lowerRight);
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
        for (Datastore mdb in mapDatabases) {
          if ((await mdb.supportsTile(tile))) {
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
    DatastoreReadResult mapReadResult = new DatastoreReadResult(pointOfInterests: [], ways: []);
    List<Future<DatastoreReadResult?>> futures = [];
    for (Datastore mdb in List.of(mapDatabases)) {
      try {
        futures.add(() async {
          if ((await mdb.supportsTile(tile))) {
            DatastoreReadResult? result = await mdb.readMapDataSingle(tile);
            return result;
          }
          return null;
        }());
      } on FileNotFoundException catch (error) {
        _log.warning("File ${error.filename} missing, removing mapfile now");
        mapDatabases.remove(mdb);
      }
    }
    bool found = false;
    List<DatastoreReadResult?> results = await Future.wait(futures);
    for (DatastoreReadResult? result in results) {
      if (result == null) {
        continue;
      }
      found = true;
      bool isWater = mapReadResult.isWater & result.isWater;
      mapReadResult.isWater = isWater;
      mapReadResult.addDeduplicate(result, deduplicate);
    }
    if (!found) return null;
    return mapReadResult;
  }

  @override
  Future<DatastoreReadResult> readMapData(Tile upperLeft, Tile lowerRight) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in mapDatabases) {
          if ((await mdb.supportsTile(upperLeft))) {
            return mdb.readMapData(upperLeft, lowerRight);
          }
        }
        return DatastoreReadResult(pointOfInterests: [], ways: []);
      case DataPolicy.RETURN_ALL:
        return _readMapDataDedup(upperLeft, lowerRight, false);
      case DataPolicy.DEDUPLICATE:
        return _readMapDataDedup(upperLeft, lowerRight, true);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreReadResult> _readMapDataDedup(Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    DatastoreReadResult mapReadResult = new DatastoreReadResult(pointOfInterests: [], ways: []);
    bool found = false;
    for (Datastore mdb in mapDatabases) {
      if ((await mdb.supportsTile(upperLeft))) {
        //_log.info("Tile3 ${upperLeft.toString()} is supported by ${mdb.toString()}");
        DatastoreReadResult result = await mdb.readMapData(upperLeft, lowerRight);
        found = true;
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    if (!found) return DatastoreReadResult(pointOfInterests: [], ways: []);
    return mapReadResult;
  }

  @override
  Future<DatastoreReadResult?> readPoiDataSingle(Tile tile) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in mapDatabases) {
          if ((await mdb.supportsTile(tile))) {
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
    DatastoreReadResult mapReadResult = new DatastoreReadResult(pointOfInterests: [], ways: []);
    for (Datastore mdb in mapDatabases) {
      if ((await mdb.supportsTile(tile))) {
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
  Future<DatastoreReadResult?> readPoiData(Tile upperLeft, Tile lowerRight) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in mapDatabases) {
          if ((await mdb.supportsTile(upperLeft))) {
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

  Future<DatastoreReadResult> _readPoiDataDedup(Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    DatastoreReadResult mapReadResult = new DatastoreReadResult(pointOfInterests: [], ways: []);
    for (Datastore mdb in mapDatabases) {
      if ((await mdb.supportsTile(upperLeft))) {
        DatastoreReadResult? result = await mdb.readPoiData(upperLeft, lowerRight);
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
  Future<bool> supportsTile(Tile tile) async {
    List<Future<bool>> futures = [];
    for (Datastore mdb in mapDatabases) {
      futures.add(() async {
        return await mdb.supportsTile(tile);
      }());
    }
    List<bool> results = await Future.wait(futures);
    for (bool result in results) {
      if (result) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<LatLong?> getStartPosition() {
    return Future.value(startPosition);
  }

  @override
  Future<int?> getStartZoomLevel() {
    return Future.value(startZoomLevel);
  }

  @override
  Future<BoundingBox> getBoundingBox() async {
    if (boundingBox != null) return boundingBox!;
    for (Datastore datastore in List.from(mapDatabases)) {
      BoundingBox? boundingBox = await datastore.getBoundingBox();
      if (null == this.boundingBox) {
        this.boundingBox = boundingBox;
      } else {
        this.boundingBox = this.boundingBox!.extendBoundingBox(boundingBox);
      }
    }
    return boundingBox!;
  }
}

/////////////////////////////////////////////////////////////////////////////

enum DataPolicy {
  RETURN_FIRST, // return the first set of data
  RETURN_ALL, // return all data from databases
  DEDUPLICATE // return all data but eliminate duplicates
}
