import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// abstract class for a datastore
///
abstract class Datastore {
  const Datastore();

  /// Reads only labels for tile. Labels are pois as well as ways that carry a name tag.
  /// It is permissible for the MapDataStore to return more data.
  /// This default implementation returns all map data, which is inefficient, but works.
  ///
  /// @param tile tile for which data is requested.
  /// @return label data for the tile.
  Future<DatastoreReadResult?> readLabelsSingle(Tile tile);

  /// Reads data for an area defined by the tile in the upper left and the tile in
  /// the lower right corner. The default implementation combines the results from
  /// all tiles, a possibly inefficient solution.
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// @param upperLeft  tile that defines the upper left corner of the requested area.
  /// @param lowerRight tile that defines the lower right corner of the requested area.
  /// @return map data for the tile.
  Future<DatastoreReadResult?> readLabels(Tile upperLeft, Tile lowerRight);

  /// Reads data for tile.
  ///
  /// @param tile tile for which data is requested.
  /// @return map data for the tile.
  Future<DatastoreReadResult?> readMapDataSingle(Tile tile);

  /// Reads data for an area defined by the tile in the upper left and the tile in
  /// the lower right corner. The default implementation combines the results from
  /// all tiles, a possibly inefficient solution.
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// @param upperLeft  tile that defines the upper left corner of the requested area.
  /// @param lowerRight tile that defines the lower right corner of the requested area.
  /// @return map data for the tile.
  Future<DatastoreReadResult?> readMapData(Tile upperLeft, Tile lowerRight);

  /**
   * Reads only POI data for tile.
   *
   * @param tile tile for which data is requested.
   * @return poi data for the tile.
   */
  Future<DatastoreReadResult?> readPoiDataSingle(Tile tile);

  /// Reads POI data for an area defined by the tile in the upper left and the tile in
  /// the lower right corner. The default implementation combines the results from
  /// all tiles, a possibly inefficient solution.
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// @param upperLeft  tile that defines the upper left corner of the requested area.
  /// @param lowerRight tile that defines the lower right corner of the requested area.
  /// @return map data for the tile.
  Future<DatastoreReadResult?> readPoiData(Tile upperLeft, Tile lowerRight);

  /// Returns true if MapDatabase contains the given tile.
  ///
  /// @param tile tile to be rendered.
  /// @return true if tile is part of database.
  bool supportsTile(Tile tile, Projection projection);

  /// Open file descriptors
  Future<void> lateOpen();
}
