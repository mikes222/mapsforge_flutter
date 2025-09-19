import 'dart:core';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/src/exceptions/mapfile_exception.dart';

/// An abstract class that defines the contract for reading map data from a
/// Mapsforge `.map` file.
///
/// This class extends the generic `Datastore` and specializes it for the
/// hierarchical and tile-based structure of map files. It provides methods to
/// read different types of data (ways, POIs, labels) for single tiles or
/// rectangular areas of tiles.
///
/// Concrete implementations of this class are responsible for opening a map file,
/// parsing its header and index, and efficiently retrieving the requested data
/// for a given tile or area.
abstract class MapDatastore extends Datastore {
  /// The preferred language to use when extracting labels from the data store.
  ///
  /// This is used by the `extractLocalized` method to select the best-matching
  /// name from multilingual strings. If `null`, the default name is used.
  final String? preferredLanguage;

  /// Constructs a [MapDatastore].
  ///
  /// [preferredLanguage] is the preferred language to use for labels. It should
  /// be a lowercase, trimmed language code (e.g., 'en', 'de').
  const MapDatastore(this.preferredLanguage);

  /// Reads only label data (POIs and named ways) for a single [tile].
  ///
  /// It is permissible for implementations to return more data than just labels.
  /// This abstract method must be implemented by concrete subclasses.
  @override
  Future<DatastoreBundle?> readLabelsSingle(Tile tile);

  /// Reads label data for a rectangular area of tiles.
  ///
  /// The default implementation iterates through all tiles from [upperLeft] to
  /// [lowerRight] and calls `readLabelsSingle` for each, combining the results.
  /// This may be inefficient and can be overridden by subclasses for better performance.
  ///
  /// Precondition: `upperLeft.tileX <= lowerRight.tileX` and `upperLeft.tileY <= lowerRight.tileY`.
  @override
  Future<DatastoreBundle?> readLabels(Tile upperLeft, Tile lowerRight) async {
    if (upperLeft.tileX > lowerRight.tileX || upperLeft.tileY > lowerRight.tileY) {
      MapFileException("upperLeft tile must be above and left of lowerRight tile");
    }
    DatastoreBundle result = DatastoreBundle(pointOfInterests: [], ways: []);
    for (int x = upperLeft.tileX; x <= lowerRight.tileX; x++) {
      for (int y = upperLeft.tileY; y <= lowerRight.tileY; y++) {
        Tile current = Tile(x, y, upperLeft.zoomLevel, upperLeft.indoorLevel);
        DatastoreBundle? r2 = await readLabelsSingle(current);
        if (r2 != null) result.addDeduplicate(r2, false);
      }
    }
    return result;
  }

  /// Reads all map data (ways and POIs) for a single [tile].
  ///
  /// This abstract method must be implemented by concrete subclasses.
  @override
  Future<DatastoreBundle?> readMapDataSingle(Tile tile);

  /// Reads all map data for a rectangular area of tiles.
  ///
  /// The default implementation iterates through all tiles from [upperLeft] to
  /// [lowerRight] and calls `readMapDataSingle` for each, combining the results.
  /// This may be inefficient and can be overridden by subclasses for better performance.
  ///
  /// Precondition: `upperLeft.tileX <= lowerRight.tileX` and `upperLeft.tileY <= lowerRight.tileY`.
  @override
  Future<DatastoreBundle> readMapData(Tile upperLeft, Tile lowerRight) async {
    if (upperLeft.tileX > lowerRight.tileX || upperLeft.tileY > lowerRight.tileY) {
      MapFileException("upperLeft tile must be above and left of lowerRight tile");
    }
    DatastoreBundle result = DatastoreBundle(pointOfInterests: [], ways: []);
    for (int x = upperLeft.tileX; x <= lowerRight.tileX; x++) {
      for (int y = upperLeft.tileY; y <= lowerRight.tileY; y++) {
        Tile current = Tile(x, y, upperLeft.zoomLevel, upperLeft.indoorLevel);
        DatastoreBundle? r2 = await readMapDataSingle(current);
        if (r2 != null) result.addDeduplicate(r2, false);
      }
    }
    return result;
  }

  /// Reads only Point of Interest (POI) data for a single [tile].
  ///
  /// This abstract method must be implemented by concrete subclasses.
  @override
  Future<DatastoreBundle?> readPoiDataSingle(Tile tile);

  /// Reads POI data for a rectangular area of tiles.
  ///
  /// The default implementation iterates through all tiles from [upperLeft] to
  /// [lowerRight] and calls `readPoiDataSingle` for each, combining the results.
  /// This may be inefficient and can be overridden by subclasses for better performance.
  ///
  /// Precondition: `upperLeft.tileX <= lowerRight.tileX` and `upperLeft.tileY <= lowerRight.tileY`.
  @override
  Future<DatastoreBundle?> readPoiData(Tile upperLeft, Tile lowerRight) async {
    if (upperLeft.tileX > lowerRight.tileX || upperLeft.tileY > lowerRight.tileY) {
      MapFileException("upperLeft tile must be above and left of lowerRight tile");
    }
    DatastoreBundle result = DatastoreBundle(pointOfInterests: [], ways: []);
    for (int x = upperLeft.tileX; x <= lowerRight.tileX; x++) {
      for (int y = upperLeft.tileY; y <= lowerRight.tileY; y++) {
        Tile current = Tile(x, y, upperLeft.zoomLevel, upperLeft.indoorLevel);
        DatastoreBundle? r2 = await readPoiDataSingle(current);
        if (r2 != null) result.addDeduplicate(r2, false);
      }
    }
    return result;
  }

  /// Gets the initial map position defined in the map file header.
  ///
  /// Returns the start position as a `LatLong`, or `null` if not available.
  Future<LatLong?> getStartPosition();

  /// Gets the initial zoom level defined in the map file header.
  ///
  /// Returns the start zoom level, or `null` if not available.
  Future<int?> getStartZoomLevel();

  /// A filter to determine if a way should be included in the result set of `readLabels`.
  ///
  /// By default, this returns `false` to exclude all ways from the label set to save
  /// memory. Subclasses can override this to include ways with specific tags
  /// (e.g., ways with names, house numbers, or refs).
  ///
  /// [tags] is the list of tags associated with the way.
  bool wayAsLabelTagFilter(List<Tag> tags) {
    return false;
  }

  /// Extracts a localized name from a multilingual string based on the [preferredLanguage].
  ///
  /// The multilingual string format consists of language-name pairs delimited by
  /// `\r`, with the language and name separated by `\b`.
  /// Example: `"Base\ren\bEnglish\rjp\bJapan\rzh_py\bPin-yin"`
  ///
  /// If a perfect match for [preferredLanguage] is found, it is returned.
  /// Otherwise, it attempts to find a fallback for a base language (e.g., 'zh' for 'zh-cn').
  /// If no match is found, the default name (the first in the string) is returned.
  String? extractLocalized(String s) {
    if (s.trim().isEmpty) {
      return null;
    }

    List<String> langNames = s.split("\r");
    if (preferredLanguage == null) {
      return langNames[0];
    }
    String lang = preferredLanguage!;

    String? fallback;
    for (int i = 1; i < langNames.length; i++) {
      List<String> langName = langNames[i].split("\b");
      if (langName.length != 2) {
        continue;
      }

      // Perfect match
      if (langName[0] == preferredLanguage) {
        return langName[1];
      }

      // Fall back to base, e.g. zh-min-lan -> zh
      if (fallback == null && !langName[0].contains("-") && (lang.contains("-") || lang.contains("_")) && lang.startsWith(langName[0])) {
        fallback = langName[1];
      }
    }
    return (fallback != null) ? fallback : langNames[0];
  }
}
