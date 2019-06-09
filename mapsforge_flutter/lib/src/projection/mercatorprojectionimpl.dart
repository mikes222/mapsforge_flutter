import 'dart:math';

import 'package:mapsforge_flutter/src/model/latlong.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

class MercatorProjectionImpl {
  /**
   * Maximum possible latitude coordinate of the map.
   */
  static final double LATITUDE_MAX = 85.05112877980659;

  /**
   * Minimum possible latitude coordinate of the map.
   */
  static final double LATITUDE_MIN = -LATITUDE_MAX;

  static final double LONGITUDE_MAX = 180;

  static final double LONGITUDE_MIN = -LONGITUDE_MAX;

  /// the size of a tile  in pixel. The whole world fits on on tile in zoomLevel 0 (=scaleFactor 1) in horizontal direction.
  final double tileSize;

  final double _scaleFactor;

  double _mapSize;

  MercatorProjectionImpl(this.tileSize, int zoomLevel) : _scaleFactor = _zoomLevelToScaleFactor(zoomLevel) {
    _mapSize = _mapSizeWithScaleFactor(_scaleFactor);
  }

  MercatorProjectionImpl.fromScaleFactor(this.tileSize, this._scaleFactor) {
    _mapSize = _mapSizeWithScaleFactor(_scaleFactor);
  }

  /// @param scaleFactor the scale factor for which the size of the world map should be returned.
  /// @return the horizontal and vertical size of the map in pixel at the given scale.
  /// @throws IllegalArgumentException if the given scale factor is < 1
  double _mapSizeWithScaleFactor(double scaleFactor) {
    assert(scaleFactor >= 1);
    return (tileSize * (pow(2, _scaleFactorToZoomLevel(scaleFactor))));
  }

  /// Converts a scaleFactor to a zoomLevel.
  /// Note that this will return a double, as the scale factors cover the
  /// intermediate zoom levels as well.
  ///
  /// @param scaleFactor the scale factor to convert to a zoom level.
  /// @return the zoom level.
  static double _scaleFactorToZoomLevel(double scaleFactor) {
    assert(scaleFactor >= 1);
    return log(scaleFactor) / log(2);
  }

  /// Converts a zoom level to a scale factor.
  ///
  /// @param zoomLevel the zoom level to convert.
  /// @return the corresponding scale factor.
  static double _zoomLevelToScaleFactor(int zoomLevel) {
    assert(zoomLevel >= 0);
    return pow(2, zoomLevel.toDouble());
  }

  /// Converts a latitude coordinate (in degrees) to a pixel Y coordinate at a certain zoom level.
  ///
  /// @param latitude  the latitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the pixel Y coordinate of the latitude value.
  double latitudeToPixelY(double latitude) {
    checkLatitude(latitude);
    double sinLatitude = sin(latitude * (pi / 180));
// FIXME improve this formula so that it works correctly without the clipping
    double pixelY = (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * pi)) * _mapSize;
    return min(max(0, pixelY), _mapSize);
  }

  /// Converts a pixel Y coordinate at a certain map size to a latitude coordinate.
  ///
  /// @param pixelY  the pixel Y coordinate that should be converted.
  /// @param mapSize precomputed size of map.
  /// @return the latitude value of the pixel Y coordinate.
  /// @throws IllegalArgumentException if the given pixelY coordinate is invalid.
  double pixelYToLatitude(double pixelY) {
    assert(pixelY >= 0);
    assert(pixelY <= _mapSize);
    double y = 0.5 - (pixelY / _mapSize);
    return 90 - 360 * atan(exp(-y * (2 * pi))) / pi;
  }

  /// Converts a longitude coordinate (in degrees) to a pixel X coordinate at a certain zoom level.
  ///
  /// @param longitude the longitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @param tileSize  the tile size
  /// @return the pixel X coordinate of the longitude value.
  double longitudeToPixelX(double longitude) {
    checkLongitude(longitude);
    return (longitude + 180) / 360 * _mapSize;
  }

  /// Converts a pixel X coordinate at a certain map size to a longitude coordinate.
  ///
  /// @param pixelX  the pixel X coordinate that should be converted.
  /// @param mapSize precomputed size of map.
  /// @return the longitude value of the pixel X coordinate.
  /// @throws IllegalArgumentException if the given pixelX coordinate is invalid.
  double pixelXToLongitude(double pixelX) {
    assert(pixelX >= 0);
    assert(pixelX <= _mapSize);
    return 360 * ((pixelX / _mapSize) - 0.5);
  }

  /// Calculates the absolute pixel position for a map size and tile size
  ///
  /// @param latLong the geographic position.
  /// @param mapSize precomputed size of map.
  /// @return the absolute pixel coordinates (for world)

  Mappoint getPixel(LatLong latLong) {
    return Mappoint(longitudeToPixelX(latLong.longitude), latitudeToPixelY(latLong.latitude));
  }

  /// Calculates the absolute pixel position for a tile and tile size relative to origin
  ///
  /// @param latLong the geographic position.
  /// @param tile    tile
  /// @return the relative pixel position to the origin values (e.g. for a tile)
  Mappoint getPixelRelativeToTile(LatLong latLong, Tile tile) {
    Mappoint mappoint = getPixel(latLong);
    return mappoint.offset(-tile.getOrigin().x, -tile.getOrigin().y);
  }

  /// Converts a longitude coordinate (in degrees) to the tile X number at a certain zoom level.
  ///
  /// @param longitude the longitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile X number of the longitude value.
  int longitudeToTileX(double longitude) {
    return pixelXToTileX(longitudeToPixelX(longitude));
  }

  /// Converts a tile X number at a certain zoom level to a longitude coordinate.
  ///
  /// @param tileX     the tile X number that should be converted.
  /// @param zoomLevel the zoom level at which the number should be converted.
  /// @return the longitude value of the tile X number.
  double tileXToLongitude(int tileX) {
    return pixelXToLongitude(tileX * tileSize);
  }

  /// Converts a tile Y number at a certain zoom level to a latitude coordinate.
  ///
  /// @param tileY     the tile Y number that should be converted.
  /// @param zoomLevel the zoom level at which the number should be converted.
  /// @return the latitude value of the tile Y number.
  double tileYToLatitude(int tileY) {
    return pixelYToLatitude(tileY * tileSize);
  }

  /// Converts a latitude coordinate (in degrees) to a tile Y number at a certain zoom level.
  ///
  /// @param latitude  the latitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile Y number of the latitude value.
  int latitudeToTileY(double latitude) {
    return pixelYToTileY(latitudeToPixelY(latitude));
  }

  /// Converts a pixel X coordinate to the tile X number.
  ///
  /// @param pixelX    the pixel X coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile X number.
  int pixelXToTileX(double pixelX) {
    return min(max(pixelX / tileSize, 0), _scaleFactor - 1).floor();
  }

  /// Converts a pixel Y coordinate to the tile Y number.
  ///
  /// @param pixelY    the pixel Y coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile Y number.
  int pixelYToTileY(double pixelY) {
    return min(max(pixelY / tileSize, 0), _scaleFactor - 1).floor();
  }

  static bool checkLatitude(double latitude) {
    assert(latitude != null);
    assert(latitude >= -90);
    assert(latitude <= 90);
    return true;
  }

  static bool checkLongitude(double longitude) {
    assert(longitude != null);
    assert(longitude >= -180);
    assert(longitude <= 180);
    return true;
  }

  double get mapSize => _mapSize;
}
