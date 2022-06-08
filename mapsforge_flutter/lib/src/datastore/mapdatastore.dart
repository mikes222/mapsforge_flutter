import 'dart:core';

import 'package:mapsforge_flutter/src/datastore/datastore.dart';

import '../model/boundingbox.dart';
import '../model/latlong.dart';
import '../model/tag.dart';
import '../model/tile.dart';
import 'datastorereadresult.dart';

/// Base class for map data retrieval.
abstract class MapDataStore extends Datastore {
  /// Extracts substring of preferred language from multilingual string.<br/>
  /// Example multilingual string: "Base\ren\bEnglish\rjp\bJapan\rzh_py\bPin-yin".
  /// <p/>
  /// Use '\r' delimiter among names and '\b' delimiter between each language and name.
  static String? extract(String s, String? language) {
    if (s.trim().length == 0) {
      return null;
    }

    List<String> langNames = s.split("\r");
    if (language == null || language.trim().length == 0) {
      return langNames[0];
    }

    String? fallback;
    for (int i = 1; i < langNames.length; i++) {
      List<String> langName = langNames[i].split("\b");
      if (langName.length != 2) {
        continue;
      }

      // Perfect match
      if (langName[0].toLowerCase() == language.toLowerCase()) {
        return langName[1];
      }

      // Fall back to base, e.g. zh-min-lan -> zh
      if (fallback == null &&
          !langName[0].contains("-") &&
          (language.contains("-") || language.contains("_")) &&
          language.toLowerCase().startsWith(langName[0].toLowerCase())) {
        fallback = langName[1];
      }
    }
    return (fallback != null) ? fallback : langNames[0];
  }

  /// the preferred language when extracting labels from this data store. The actual
  /// implementation is up to the concrete implementation, which can also simply ignore
  /// this setting.
  final String? preferredLanguage;

  /// Ctor for MapDataStore setting preferred language.
  ///
  /// @param language the preferred language or null if default language is used.
  const MapDataStore(String? language) : preferredLanguage = language;

  /// Returns the area for which data is supplied.
  ///
  /// @return bounding box of area.
  BoundingBox? get boundingBox;

  /// Extracts substring of preferred language from multilingual string using
  /// the preferredLanguage setting.
  String? extractLocalized(String s) {
    return MapDataStore.extract(s, preferredLanguage);
  }

  /// Returns the timestamp of the data used to render a specific tile.
  ///
  /// @param tile A tile.
  /// @return the timestamp of the data used to render the tile
  int? getDataTimestamp(Tile tile);

  /// Reads only labels for tile. Labels are pois as well as ways that carry a name tag.
  /// It is permissible for the MapDataStore to return more data.
  /// This default implementation returns all map data, which is inefficient, but works.
  ///
  /// @param tile tile for which data is requested.
  /// @return label data for the tile.
  @override
  Future<DatastoreReadResult?> readLabelsSingle(Tile tile) async {
    return readMapDataSingle(tile);
  }

  /// Reads data for an area defined by the tile in the upper left and the tile in
  /// the lower right corner. The default implementation combines the results from
  /// all tiles, a possibly inefficient solution.
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// @param upperLeft  tile that defines the upper left corner of the requested area.
  /// @param lowerRight tile that defines the lower right corner of the requested area.
  /// @return map data for the tile.
  @override
  Future<DatastoreReadResult?> readLabels(
      Tile upperLeft, Tile lowerRight) async {
    if (upperLeft.tileX > lowerRight.tileX ||
        upperLeft.tileY > lowerRight.tileY) {
      new Exception("upperLeft tile must be above and left of lowerRight tile");
    }
    DatastoreReadResult result =
        new DatastoreReadResult(pointOfInterests: [], ways: []);
    for (int x = upperLeft.tileX; x <= lowerRight.tileX; x++) {
      for (int y = upperLeft.tileY; y <= lowerRight.tileY; y++) {
        Tile current =
            new Tile(x, y, upperLeft.zoomLevel, upperLeft.indoorLevel);
        DatastoreReadResult? r2 = await readLabelsSingle(current);
        if (r2 != null) result.addDeduplicate(r2, false);
      }
    }
    return result;
  }

  /// Reads data for tile.
  ///
  /// @param tile tile for which data is requested.
  /// @return map data for the tile.
  @override
  Future<DatastoreReadResult?> readMapDataSingle(Tile tile);

  /// Reads data for an area defined by the tile in the upper left and the tile in
  /// the lower right corner. The default implementation combines the results from
  /// all tiles, a possibly inefficient solution.
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// @param upperLeft  tile that defines the upper left corner of the requested area.
  /// @param lowerRight tile that defines the lower right corner of the requested area.
  /// @return map data for the tile.
  @override
  Future<DatastoreReadResult?> readMapData(
      Tile upperLeft, Tile lowerRight) async {
    if (upperLeft.tileX > lowerRight.tileX ||
        upperLeft.tileY > lowerRight.tileY) {
      new Exception("upperLeft tile must be above and left of lowerRight tile");
    }
    DatastoreReadResult result =
        new DatastoreReadResult(pointOfInterests: [], ways: []);
    for (int x = upperLeft.tileX; x <= lowerRight.tileX; x++) {
      for (int y = upperLeft.tileY; y <= lowerRight.tileY; y++) {
        Tile current =
            new Tile(x, y, upperLeft.zoomLevel, upperLeft.indoorLevel);
        DatastoreReadResult? r2 = await readMapDataSingle(current);
        if (r2 != null) result.addDeduplicate(r2, false);
      }
    }
    return result;
  }

  /**
   * Reads only POI data for tile.
   *
   * @param tile tile for which data is requested.
   * @return poi data for the tile.
   */
  @override
  Future<DatastoreReadResult?> readPoiDataSingle(Tile tile);

  /// Reads POI data for an area defined by the tile in the upper left and the tile in
  /// the lower right corner. The default implementation combines the results from
  /// all tiles, a possibly inefficient solution.
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// @param upperLeft  tile that defines the upper left corner of the requested area.
  /// @param lowerRight tile that defines the lower right corner of the requested area.
  /// @return map data for the tile.
  @override
  Future<DatastoreReadResult?> readPoiData(
      Tile upperLeft, Tile lowerRight) async {
    if (upperLeft.tileX > lowerRight.tileX ||
        upperLeft.tileY > lowerRight.tileY) {
      new Exception("upperLeft tile must be above and left of lowerRight tile");
    }
    DatastoreReadResult result =
        new DatastoreReadResult(pointOfInterests: [], ways: []);
    for (int x = upperLeft.tileX; x <= lowerRight.tileX; x++) {
      for (int y = upperLeft.tileY; y <= lowerRight.tileY; y++) {
        Tile current =
            new Tile(x, y, upperLeft.zoomLevel, upperLeft.indoorLevel);
        DatastoreReadResult? r2 = await readPoiDataSingle(current);
        if (r2 != null) result.addDeduplicate(r2, false);
      }
    }
    return result;
  }

  /// Gets the initial map position.
  ///
  /// @return the start position, if available.
  LatLong? get startPosition;

  /**
   * Gets the initial zoom level.
   *
   * @return the start zoom level.
   */
  int? get startZoomLevel;

  /// Returns true if a way should be included in the result set for readLabels()
  /// By default only ways with names, house numbers or a ref are included in the result set
  /// of readLabels(). This is to reduce the set of ways as much as possible to save memory.
  /// @param tags the tags associated with the way
  /// @return true if the way should be included in the result set
  bool wayAsLabelTagFilter(List<Tag> tags) {
    return false;
  }
}
