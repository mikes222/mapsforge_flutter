import 'dart:async';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';

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
class MultimapDatastore extends Datastore {
  static final _log = Logger('MultiMapDataStore');

  /// The bounding box of all included datastores
  BoundingBox? _boundingBox;

  final DataPolicy dataPolicy;

  /// A list of map datastores
  final Set<Datastore> datastores = {};

  /// A map tracking the boundary of each datastore for optimization
  final Map<Datastore, BoundingBox> _datastoreBoundaries = {};

  LatLong? startPosition;

  int? startZoomLevel;

  MultimapDatastore(this.dataPolicy);

  @override
  void dispose() {
    for (var db in datastores) {
      db.dispose();
    }
  }

  /// adds another mapDataStore
  ///
  /// @param mapDataStore      the mapDataStore to add
  Future<void> addDatastore(Datastore datastore) async {
    if (datastores.contains(datastore)) {
      throw Exception("Duplicate map database");
    }
    datastores.add(datastore);

    // Get and cache the datastore's boundary
    BoundingBox datastoreBoundary = await datastore.getBoundingBox();
    _datastoreBoundaries[datastore] = datastoreBoundary;

    if (_boundingBox != null) _boundingBox = _boundingBox!.extendBoundingBox(datastoreBoundary);
  }

  Future<void> removeDatastore(double minLatitude, double minLongitude, double maxLatitude, double maxLongitude) async {
    BoundingBox toRemove = BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
    _boundingBox = null;
    final List<Datastore> datastoresList = datastores.toList();

    // Fetch all boundaries in parallel, using the cache when available.
    final List<Future<BoundingBox>> futures = [];
    for (Datastore datastore in datastoresList) {
      BoundingBox? datastoreBoundary = _datastoreBoundaries[datastore];
      futures.add(datastoreBoundary != null ? Future.value(datastoreBoundary) : datastore.getBoundingBox());
    }
    final List<BoundingBox> boundaries = await Future.wait(futures);

    for (int i = 0; i < datastoresList.length; ++i) {
      Datastore datastore = datastoresList[i];
      BoundingBox datastoreBoundary = boundaries[i];
      _datastoreBoundaries[datastore] = datastoreBoundary;
      if (toRemove.intersects(datastoreBoundary)) {
        datastores.remove(datastore);
        _datastoreBoundaries.remove(datastore);
      } else {
        if (null == _boundingBox) {
          _boundingBox = datastoreBoundary;
        } else {
          _boundingBox = _boundingBox!.extendBoundingBox(datastoreBoundary);
        }
      }
    }
  }

  void removeAllDatastores() {
    _boundingBox = null;
    startPosition = null;
    startZoomLevel = null;
    datastores.clear();
    _datastoreBoundaries.clear();
  }

  /// Checks if a datastore's boundary intersects with the given tile's boundary
  /// Returns true if intersection exists or if boundary is not cached (fallback to supportsTile)
  bool _datastoreIntersectsTile(Datastore datastore, Tile tile) {
    BoundingBox? datastoreBoundary = _datastoreBoundaries[datastore];
    if (datastoreBoundary == null) {
      // Fallback to original behavior if boundary not cached
      return true;
    }

    BoundingBox tileBoundary = tile.getBoundingBox();
    return datastoreBoundary.intersects(tileBoundary);
  }

  /// Getter for accessing datastore boundaries (primarily for testing)
  Map<Datastore, BoundingBox> get datastoreBoundaries => Map.unmodifiable(_datastoreBoundaries);

  @override
  Future<DatastoreBundle?> readLabelsSingle(Tile tile) async {
    final List<Datastore> datastoresList = datastores.toList();
    switch (dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in datastoresList) {
          if (_datastoreIntersectsTile(mdb, tile) && (await mdb.supportsTile(tile))) {
            return mdb.readLabelsSingle(tile);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readLabelsDedup(tile, false, datastoresList);
      case DataPolicy.DEDUPLICATE:
        return _readLabelsDedup(tile, true, datastoresList);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreBundle> _readLabelsDedup(Tile tile, bool deduplicate, List<Datastore> datastoresList) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    List<Future<DatastoreBundle?>> futures = [];
    for (Datastore mdb in datastoresList) {
      futures.add(() async {
        if (_datastoreIntersectsTile(mdb, tile) && (await mdb.supportsTile(tile))) {
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
    final List<Datastore> datastoresList = datastores.toList();
    switch (dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in datastoresList) {
          if (_datastoreIntersectsTile(mdb, upperLeft) && (await mdb.supportsTile(upperLeft))) {
            return mdb.readLabels(upperLeft, lowerRight);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readLabels(upperLeft, lowerRight, false, datastoresList);
      case DataPolicy.DEDUPLICATE:
        return _readLabels(upperLeft, lowerRight, true, datastoresList);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreBundle> _readLabels(Tile upperLeft, Tile lowerRight, bool deduplicate, List<Datastore> datastoresList) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    List<Future<DatastoreBundle?>> futures = [];
    for (Datastore mdb in datastoresList) {
      futures.add(() async {
        if (_datastoreIntersectsTile(mdb, upperLeft) && (await mdb.supportsTile(upperLeft))) {
          DatastoreBundle? result = await mdb.readLabels(upperLeft, lowerRight);
          return result;
        }
        return null;
      }());
    }
    List<DatastoreBundle?> results = await Future.wait(futures);
    for (DatastoreBundle? result in results) {
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
  Future<DatastoreBundle?> readMapDataSingle(Tile tile) async {
    final List<Datastore> datastoresList = datastores.toList();
    switch (dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in datastoresList) {
          if (_datastoreIntersectsTile(mdb, tile) && (await mdb.supportsTile(tile))) {
            return mdb.readMapDataSingle(tile);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readMapData(tile, false, datastoresList);
      case DataPolicy.DEDUPLICATE:
        return _readMapData(tile, true, datastoresList);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreBundle?> _readMapData(Tile tile, bool deduplicate, List<Datastore> datastoresList) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    List<Future<DatastoreBundle?>> futures = [];
    for (Datastore mdb in datastoresList) {
      try {
        futures.add(() async {
          if (_datastoreIntersectsTile(mdb, tile) && (await mdb.supportsTile(tile))) {
            DatastoreBundle? result = await mdb.readMapDataSingle(tile);
            return result;
          }
          return null;
        }());
      } on Exception catch (error) {
        _log.warning("File error $error missing, removing mapfile now");
        datastores.remove(mdb);
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
    final List<Datastore> datastoresList = datastores.toList();
    switch (dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in datastoresList) {
          if (_datastoreIntersectsTile(mdb, upperLeft) && (await mdb.supportsTile(upperLeft))) {
            return mdb.readMapData(upperLeft, lowerRight);
          }
        }
        return DatastoreBundle(pointOfInterests: [], ways: []);
      case DataPolicy.RETURN_ALL:
        return _readMapDataDedup(upperLeft, lowerRight, false, datastoresList);
      case DataPolicy.DEDUPLICATE:
        return _readMapDataDedup(upperLeft, lowerRight, true, datastoresList);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreBundle> _readMapDataDedup(Tile upperLeft, Tile lowerRight, bool deduplicate, List<Datastore> datastoresList) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    List<Future<DatastoreBundle?>> futures = [];
    for (Datastore mdb in datastoresList) {
      futures.add(() async {
        if (_datastoreIntersectsTile(mdb, upperLeft) && (await mdb.supportsTile(upperLeft))) {
          //_log.info("Tile3 ${upperLeft.toString()} is supported by ${mdb.toString()}");
          DatastoreBundle result = await mdb.readMapData(upperLeft, lowerRight);
          return result;
        }
        return null;
      }());
    }
    List<DatastoreBundle?> results = await Future.wait(futures);
    bool found = false;
    for (DatastoreBundle? result in results) {
      if (result == null) {
        continue;
      }
      found = true;
      bool isWater = mapReadResult.isWater & result.isWater;
      mapReadResult.isWater = isWater;
      mapReadResult.addDeduplicate(result, deduplicate);
    }
    if (!found) return DatastoreBundle(pointOfInterests: [], ways: []);
    return mapReadResult;
  }

  @override
  Future<DatastoreBundle?> readPoiDataSingle(Tile tile) async {
    final List<Datastore> datastoresList = datastores.toList();
    switch (dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in datastoresList) {
          if (_datastoreIntersectsTile(mdb, tile) && (await mdb.supportsTile(tile))) {
            return mdb.readPoiDataSingle(tile);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readPoiData(tile, false, datastoresList);
      case DataPolicy.DEDUPLICATE:
        return _readPoiData(tile, true, datastoresList);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreBundle> _readPoiData(Tile tile, bool deduplicate, List<Datastore> datastoresList) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    List<Future<DatastoreBundle?>> futures = [];
    for (Datastore mdb in datastoresList) {
      futures.add(() async {
        if (_datastoreIntersectsTile(mdb, tile) && (await mdb.supportsTile(tile))) {
          DatastoreBundle? result = await mdb.readPoiDataSingle(tile);
          return result;
        }
        return null;
      }());
    }
    List<DatastoreBundle?> results = await Future.wait(futures);
    for (DatastoreBundle? result in results) {
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
  Future<DatastoreBundle?> readPoiData(Tile upperLeft, Tile lowerRight) async {
    final List<Datastore> datastoresList = datastores.toList();
    switch (dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (Datastore mdb in datastoresList) {
          if (_datastoreIntersectsTile(mdb, upperLeft) && (await mdb.supportsTile(upperLeft))) {
            return mdb.readPoiData(upperLeft, lowerRight);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readPoiDataDedup(upperLeft, lowerRight, false, datastoresList);
      case DataPolicy.DEDUPLICATE:
        return _readPoiDataDedup(upperLeft, lowerRight, true, datastoresList);
    }
    //throw new Exception("Invalid data policy for multi map database");
  }

  Future<DatastoreBundle> _readPoiDataDedup(Tile upperLeft, Tile lowerRight, bool deduplicate, List<Datastore> datastoresList) async {
    DatastoreBundle mapReadResult = DatastoreBundle(pointOfInterests: [], ways: []);
    List<Future<DatastoreBundle?>> futures = [];
    for (Datastore mdb in datastoresList) {
      futures.add(() async {
        if (_datastoreIntersectsTile(mdb, upperLeft) && (await mdb.supportsTile(upperLeft))) {
          DatastoreBundle? result = await mdb.readPoiData(upperLeft, lowerRight);
          return result;
        }
        return null;
      }());
    }
    List<DatastoreBundle?> results = await Future.wait(futures);
    for (DatastoreBundle? result in results) {
      if (result == null) {
        continue;
      }
      bool isWater = mapReadResult.isWater & result.isWater;
      mapReadResult.isWater = isWater;
      mapReadResult.addDeduplicate(result, deduplicate);
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
    final List<Datastore> datastoresList = datastores.toList();
    List<Future<bool>> futures = [];
    for (Datastore mdb in datastoresList) {
      futures.add(() {
        if (_datastoreIntersectsTile(mdb, tile)) {
          return mdb.supportsTile(tile);
        }
        return Future.value(false);
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
    if (_boundingBox != null) return _boundingBox!;
    final List<Datastore> datastoresList = datastores.toList();

    // Fetch all boundaries in parallel, using the cache when available.
    final List<Future<BoundingBox>> futures = [];
    for (Datastore datastore in datastoresList) {
      BoundingBox? boundingBox = _datastoreBoundaries[datastore];
      futures.add(boundingBox != null ? Future.value(boundingBox) : datastore.getBoundingBox());
    }
    final List<BoundingBox> boundaries = await Future.wait(futures);

    for (int i = 0; i < datastoresList.length; ++i) {
      Datastore datastore = datastoresList[i];
      BoundingBox boundingBox = boundaries[i];
      _datastoreBoundaries[datastore] = boundingBox;

      if (null == _boundingBox) {
        _boundingBox = boundingBox;
      } else {
        _boundingBox = _boundingBox!.extendBoundingBox(boundingBox);
      }
    }
    return _boundingBox!;
  }
}

/////////////////////////////////////////////////////////////////////////////

enum DataPolicy {
  RETURN_FIRST, // return the first set of data
  RETURN_ALL, // return all data from databases
  DEDUPLICATE, // return all data but eliminate duplicates
}
