import 'dart:async';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:dart_mapfile/src/exceptions/file_not_found_exception.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:logging/logging.dart';

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
class MultiMapDataStore extends Datastore {
  static final _log = Logger('MultiMapDataStore');

  BoundingBox? boundingBox;
  final DataPolicy dataPolicy;
  final List<Datastore> mapDatabases;

  LatLong? startPosition;

  int? startZoomLevel;

  MultiMapDataStore(this.dataPolicy) : mapDatabases = [], super();

  @override
  void dispose() {
    for (var db in mapDatabases) {
      db.dispose();
    }
  }

  /// adds another mapDataStore
  ///
  /// @param mapDataStore      the mapDataStore to add
  Future<void> addMapDataStore(Datastore mapDataStore) async {
    if (mapDatabases.contains(mapDataStore)) {
      throw Exception("Duplicate map database");
    }
    mapDatabases.add(mapDataStore);
  }

  Future<void> removeMapDataStore(double minLatitude, double minLongitude, double maxLatitude, double maxLongitude) async {
    BoundingBox toRemove = BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
    boundingBox = null;
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
    boundingBox = null;
    startPosition = null;
    startZoomLevel = null;
    mapDatabases.clear();
  }

  @override
  Future<DatastoreBundle?> readLabelsSingle(Tile tile) async {
    switch (dataPolicy) {
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

  Future<DatastoreBundle> _readLabelsDedup(Tile tile, bool deduplicate) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    List<Future<DatastoreBundle?>> futures = [];
    for (Datastore mdb in List.from(mapDatabases)) {
      futures.add(() async {
        if ((await mdb.supportsTile(tile))) {
          //_log.info("Tile ${tile.toString()} is supported by ${mdb.toString()}");
          DatastoreBundle? result = await mdb.readLabelsSingle(tile);
          return result;
        }
        return null;
      }());
    }
    List<DatastoreBundle?> results = await Future.wait(futures);
    for (var result in results) {
      if (result == null) {
        continue;
      }
      bool isWater = mapReadResult.isWater & result.isWater;
      mapReadResult.isWater = isWater;
      mapReadResult.addDeduplicate(result, deduplicate);
    }
    return mapReadResult;
  }

  @override
  Future<DatastoreBundle?> readLabels(Tile upperLeft, Tile lowerRight) async {
    switch (dataPolicy) {
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

  Future<DatastoreBundle> _readLabels(Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    for (Datastore mdb in mapDatabases) {
      if ((await mdb.supportsTile(upperLeft))) {
        DatastoreBundle? result = await mdb.readLabels(upperLeft, lowerRight);
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
  Future<DatastoreBundle?> readMapDataSingle(Tile tile) async {
    switch (dataPolicy) {
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

  Future<DatastoreBundle?> _readMapData(Tile tile, bool deduplicate) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    List<Future<DatastoreBundle?>> futures = [];
    for (Datastore mdb in List.of(mapDatabases)) {
      try {
        futures.add(() async {
          if ((await mdb.supportsTile(tile))) {
            DatastoreBundle? result = await mdb.readMapDataSingle(tile);
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
    List<DatastoreBundle?> results = await Future.wait(futures);
    for (DatastoreBundle? result in results) {
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
  Future<DatastoreBundle> readMapData(Tile upperLeft, Tile lowerRight) async {
    switch (dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in mapDatabases) {
          if ((await mdb.supportsTile(upperLeft))) {
            return mdb.readMapData(upperLeft, lowerRight);
          }
        }
        return DatastoreBundle(pointOfInterests: [], ways: []);
      case DataPolicy.RETURN_ALL:
        return _readMapDataDedup(upperLeft, lowerRight, false);
      case DataPolicy.DEDUPLICATE:
        return _readMapDataDedup(upperLeft, lowerRight, true);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreBundle> _readMapDataDedup(Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    bool found = false;
    for (Datastore mdb in mapDatabases) {
      if ((await mdb.supportsTile(upperLeft))) {
        //_log.info("Tile3 ${upperLeft.toString()} is supported by ${mdb.toString()}");
        DatastoreBundle result = await mdb.readMapData(upperLeft, lowerRight);
        found = true;
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    if (!found) return DatastoreBundle(pointOfInterests: [], ways: []);
    return mapReadResult;
  }

  @override
  Future<DatastoreBundle?> readPoiDataSingle(Tile tile) async {
    switch (dataPolicy) {
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

  Future<DatastoreBundle> _readPoiData(Tile tile, bool deduplicate) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    for (Datastore mdb in mapDatabases) {
      if ((await mdb.supportsTile(tile))) {
        DatastoreBundle? result = await mdb.readPoiDataSingle(tile);
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
  Future<DatastoreBundle?> readPoiData(Tile upperLeft, Tile lowerRight) async {
    switch (dataPolicy) {
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

  Future<DatastoreBundle> _readPoiDataDedup(Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    for (Datastore mdb in mapDatabases) {
      if ((await mdb.supportsTile(upperLeft))) {
        DatastoreBundle? result = await mdb.readPoiData(upperLeft, lowerRight);
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
  DEDUPLICATE, // return all data but eliminate duplicates
}
