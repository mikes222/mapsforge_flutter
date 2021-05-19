import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// This class provides the calculation from Lat/Lon to pixelY/pixelX and vice versa
///
abstract class Projection {
  /// The equatorial radius as defined by the <a href="http://en.wikipedia.org/wiki/World_Geodetic_System">WGS84
  /// ellipsoid</a>. WGS84 is the reference coordinate system used by the Global Positioning System.
  static final double EQUATORIAL_RADIUS = 6378137.0;

  /// Maximum possible latitude coordinate of the map.
  static final double LATITUDE_MAX = 85.05112877980659;

  /// Minimum possible latitude coordinate of the map.
  static final double LATITUDE_MIN = -LATITUDE_MAX;

  /// The circumference of the earth at the equator in meters.
  //static final double EARTH_CIRCUMFERENCE = 40075016.686;

  /// Polar radius in meter (WGS84 ellipsoid)
  //static final double POLAR_RADIUS = 6356752.314245;

  static final double LONGITUDE_MAX = 180;

  static final double LONGITUDE_MIN = -LONGITUDE_MAX;

//  static void checkLatitude(double latitude) {
  // assert(latitude >= LATITUDE_MIN);
  // assert(latitude <= LATITUDE_MAX);
//  }

//  static void checkLongitude(double longitude) {
  // assert(longitude >= LONGITUDE_MIN);
  // assert(longitude <= LONGITUDE_MAX);
//  }

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

    final double a = distanceInMeter / EQUATORIAL_RADIUS;

    final double lat2 = asin(sin(degToRadian(from.latitude)) * cos(a) + cos(degToRadian(from.latitude)) * sin(a) * cos(h));

    final double lng2 = degToRadian(from.longitude) +
        atan2(sin(h) * sin(a) * cos(degToRadian(from.latitude)), cos(a) - sin(degToRadian(from.latitude)) * sin(lat2));

    return new LatLong(radianToDeg(lat2), radianToDeg(lng2));
  }

  /// Calculates distance with Haversine algorithm.
  ///
  /// Accuracy can be out by 0.3%
  /// More on [Wikipedia](https://en.wikipedia.org/wiki/Haversine_formula)
  //@override
  static double distance(final ILatLong p1, final ILatLong p2) {
    final sinDLat = sin((degToRadian(p2.latitude) - degToRadian(p1.latitude)) / 2);
    final sinDLng = sin((degToRadian(p2.longitude) - degToRadian(p1.longitude)) / 2);

    // Sides
    final a = sinDLat * sinDLat + sinDLng * sinDLng * cos(degToRadian(p1.latitude)) * cos(degToRadian(p2.latitude));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return EQUATORIAL_RADIUS * c;
  }

  /**
   * Calculates the amount of degrees of latitude for a given distance in meters.
   *
   * @param meters distance in meters
   * @return latitude degrees
   */
  static double latitudeDistance(int meters) {
    return (meters * 360) / (2 * pi * EQUATORIAL_RADIUS);
  }

  /**
   * Calculates the amount of degrees of longitude for a given distance in meters.
   *
   * @param meters   distance in meters
   * @param latitude the latitude at which the calculation should be performed
   * @return longitude degrees
   */
  static double longitudeDistance(int meters, double latitude) {
    return (meters * 360) / (2 * pi * EQUATORIAL_RADIUS * cos(degToRadian(latitude)));
  }

  /////////////////////////////////////////////////////////////////////////////

  //double get scaleFactor;

  /// Converts a tile Y number at a certain zoom level to a latitude coordinate.
  ///
  /// @param tileY     the tile Y number that should be converted.
  /// @param zoomLevel the zoom level at which the number should be converted.
  /// @return the latitude value of the tile Y number.
  double tileYToLatitude(int tileY);

  /// Converts a tile X number at a certain zoom level to a longitude coordinate.
  ///
  /// @param tileX     the tile X number that should be converted.
  /// @param zoomLevel the zoom level at which the number should be converted.
  /// @return the longitude value of the tile X number.
  double tileXToLongitude(int tileX);

  /// Converts a latitude coordinate (in degrees) to a tile Y number at a certain zoom level.
  ///
  /// @param latitude  the latitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile Y number of the latitude value.
  int latitudeToTileY(double latitude);

  /// Converts a longitude coordinate (in degrees) to the tile X number at a certain zoom level.
  ///
  /// @param longitude the longitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile X number of the longitude value.
  int longitudeToTileX(double longitude);

  BoundingBox boundingBoxOfTile(Tile tile);

  BoundingBox boundingBoxOfTiles(Tile upperLeft, Tile lowerRight);
}
