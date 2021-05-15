import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/model/latlong.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

class MercatorProjectionImpl {
  static final _log = new Logger('MercatorProjectionImpl');

  /// Maximum possible latitude coordinate of the map.
  static final double LATITUDE_MAX = 85.05112877980659;

  /// Minimum possible latitude coordinate of the map.
  static final double LATITUDE_MIN = -LATITUDE_MAX;

  /// The circumference of the earth at the equator in meters.
  //static final double EARTH_CIRCUMFERENCE = 40075016.686;

  /// Equator radius in meter (WGS84 ellipsoid)
  static final double EQUATOR_RADIUS = 6378137.0;

  /// Polar radius in meter (WGS84 ellipsoid)
  //static final double POLAR_RADIUS = 6356752.314245;

  static final double LONGITUDE_MAX = 180;

  static final double LONGITUDE_MIN = -LONGITUDE_MAX;

  /// the size of a tile  in pixel. Each tile has the same width and height.
  final double tileSize;

  ///
  /// The scalefactor. The scaleFactor is dependent on the zoomLevel (scaleFactor similar to pow(2, zoomLevel) ). The whole world fits into on tile in zoomLevel 0 (=scaleFactor 1).
  final double _scaleFactor;

  ///
  /// the size of the map in pixel. At scalefactor 1 the _mapSize is equal to the tileSize.
  ///
  double? _mapSize;

  MercatorProjectionImpl(this.tileSize, int zoomLevel) : _scaleFactor = zoomLevelToScaleFactor(zoomLevel) {
    _mapSize = _mapSizeWithScaleFactor(_scaleFactor);
  }

  MercatorProjectionImpl.fromScaleFactor(this.tileSize, this._scaleFactor) {
    _mapSize = _mapSizeWithScaleFactor(_scaleFactor);
  }

  double get scaleFactor => _scaleFactor;

  /// @param scaleFactor the scale factor for which the size of the world map should be returned.
  /// @return the horizontal and vertical size of the map in pixel at the given scale.
  /// @throws IllegalArgumentException if the given scale factor is < 1
  double _mapSizeWithScaleFactor(double scaleFactor) {
    assert(scaleFactor >= 1);
    return (tileSize * (pow(2, scaleFactorToZoomLevel(scaleFactor))));
  }

  /// Converts a scaleFactor to a zoomLevel.
  /// Note that this will return a double, as the scale factors cover the
  /// intermediate zoom levels as well.
  ///
  /// @param scaleFactor the scale factor to convert to a zoom level.
  /// @return the zoom level.
  static double scaleFactorToZoomLevel(double scaleFactor) {
    assert(scaleFactor >= 1);
    return log(scaleFactor) / log(2);
  }

  /// Converts a zoom level to a scale factor.
  ///
  /// @param zoomLevel the zoom level to convert.
  /// @return the corresponding scale factor.
  static double zoomLevelToScaleFactor(int zoomLevel) {
    assert(zoomLevel >= 0 && zoomLevel <= 65535);
    return pow(2, zoomLevel.toDouble()) as double;
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
    double pixelY = (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * pi)) * _mapSize!;
    return min(max(0, pixelY), _mapSize!);
  }

  /// Converts a pixel Y coordinate at a certain map size to a latitude coordinate.
  ///
  /// @param pixelY  the pixel Y coordinate that should be converted.
  /// @param mapSize precomputed size of map.
  /// @return the latitude value of the pixel Y coordinate.
  /// @throws IllegalArgumentException if the given pixelY coordinate is invalid.
  double pixelYToLatitude(double pixelY) {
    assert(pixelY >= 0);
    assert(pixelY <= _mapSize!);
    double y = 0.5 - (pixelY / _mapSize!);
    return 90 - 360 * atan(exp(-y * (2 * pi))) / pi;
  }

  ILatLong getLatLong(double pixelX, double pixelY) {
    return LatLong(pixelYToLatitude(pixelY), pixelXToLongitude(pixelX));
  }

  /// Converts a longitude coordinate (in degrees) to a pixel X coordinate at a certain zoom level.
  ///
  /// @param longitude the longitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @param tileSize  the tile size
  /// @return the pixel X coordinate of the longitude value.
  double longitudeToPixelX(double longitude) {
    checkLongitude(longitude);
    return (longitude + 180) / 360 * _mapSize!;
  }

  /// Converts a pixel X coordinate at a certain map size to a longitude coordinate.
  ///
  /// @param pixelX  the pixel X coordinate that should be converted.
  /// @param mapSize precomputed size of map.
  /// @return the longitude value of the pixel X coordinate.
  /// @throws IllegalArgumentException if the given pixelX coordinate is invalid.
  double pixelXToLongitude(double pixelX) {
    assert(pixelX >= 0);
    assert(pixelX <= _mapSize!);
    return 360 * ((pixelX / _mapSize!) - 0.5);
  }

  /// Calculates the absolute pixel position for a map size and tile size
  ///
  /// @param latLong the geographic position.
  /// @param mapSize precomputed size of map.
  /// @return the absolute pixel coordinates (for world)

  Mappoint getPixel(ILatLong latLong) {
    assert(latLong != null);
    return Mappoint(longitudeToPixelX(latLong.longitude!), latitudeToPixelY(latLong.latitude!));
  }

  /// Calculates the absolute pixel position for a tile and tile size relative to origin
  ///
  /// @param latLong the geographic position.
  /// @param tile    tile
  /// @return the relative pixel position to the origin values (e.g. for a tile)
  Mappoint getPixelRelativeToTile(ILatLong latLong, Tile tile) {
    Mappoint mappoint = getPixel(latLong);
    return mappoint.offset(-tile.getLeftUpper(tileSize).x, -tile.getLeftUpper(tileSize).y);
  }

  /// Calculates the absolute pixel position for a tile and tile size relative to origin
  ///
  /// @param latLong the geographic position.
  /// @param tile    tile
  /// @return the relative pixel position to the origin values (e.g. for a tile)
  Mappoint getPixelRelativeToLeftUpper(ILatLong latLong, Mappoint leftUpper) {
    assert(latLong != null);
    assert(leftUpper != null);
    Mappoint mappoint = getPixel(latLong);
    return mappoint.offset(-leftUpper.x, -leftUpper.y);
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

  double? get mapSize => _mapSize;

  /// Converts degree to radian
  static double degToRadian(final double deg) => deg * (pi / 180.0);

  /// Radian to degree
  static double radianToDeg(final double rad) => rad * (180.0 / pi);

  /// Returns a destination point based on the given [distance] and [bearing]
  ///
  /// Given a [from] (start) point, initial [bearing], and [distance],
  /// this will calculate the destination point and
  /// final bearing travelling along a (shortest distance) great circle arc.
  ///
  ///     final Haversine distance = const Haversine();
  ///
  ///     final num distanceInMeter = (EARTH_RADIUS * math.PI / 4).round();
  ///
  ///     final p1 = new LatLng(0.0, 0.0);
  ///     final p2 = distance.offset(p1, distanceInMeter, 180);
  ///
  //@override
  static ILatLong offset(final ILatLong from, final double distanceInMeter, double bearing) {
    assert(bearing >= 0 && bearing <= 360);
// bearing: 0: north, 90: east, 180: south, 270: west
    //bearing = 90 - bearing;

    // 0: east, 90: north, +/- 180: west, -90: south
    final double h = bearing / 180 * pi;

    final double a = distanceInMeter / EQUATOR_RADIUS;

    final double lat2 = asin(sin(degToRadian(from.latitude!)) * cos(a) + cos(degToRadian(from.latitude!)) * sin(a) * cos(h));

    final double lng2 = degToRadian(from.longitude!) +
        atan2(sin(h) * sin(a) * cos(degToRadian(from.latitude!)), cos(a) - sin(degToRadian(from.latitude!)) * sin(lat2));

    return new LatLong(radianToDeg(lat2), radianToDeg(lng2));
  }

  /// Calculates distance with Haversine algorithm.
  ///
  /// Accuracy can be out by 0.3%
  /// More on [Wikipedia](https://en.wikipedia.org/wiki/Haversine_formula)
  //@override
  static double distance(final ILatLong p1, final ILatLong p2) {
    final sinDLat = sin((degToRadian(p2.latitude!) - degToRadian(p1.latitude!)) / 2);
    final sinDLng = sin((degToRadian(p2.longitude!) - degToRadian(p1.longitude!)) / 2);

    // Sides
    final a = sinDLat * sinDLat + sinDLng * sinDLng * cos(degToRadian(p1.latitude!)) * cos(degToRadian(p2.latitude!));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return EQUATOR_RADIUS * c;
  }
}
