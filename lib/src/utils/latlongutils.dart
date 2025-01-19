import 'dart:math';

import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import '../model/latlong.dart';

class LatLongUtils {
  /**
   * The equatorial radius as defined by the <a href="http://en.wikipedia.org/wiki/World_Geodetic_System">WGS84
   * ellipsoid</a>. WGS84 is the reference coordinate system used by the Global Positioning System.
   */
  static final double EQUATORIAL_RADIUS = 6378137.0;

  /// Polar radius of earth is required for distance computation.
  static final double POLAR_RADIUS = 6356752.3142;

  /**
   * Conversion factor from degrees to microdegrees.
   */
  static final double CONVERSION_FACTOR = 1000000.0;

  static final String DELIMITER = ",";

  /**
   * Find if the given point lies within this polygon.
   * <p>
   * http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
   *
   * @return true if this polygon contains the given point, false otherwise.
   */
  static bool contains(List<ILatLong> latLongs, ILatLong latLong) {
    bool result = false;
    for (int i = 0, j = latLongs.length - 1; i < latLongs.length; j = i++) {
      if ((latLongs[i].latitude > latLong.latitude) !=
              (latLongs[j].latitude > latLong.latitude) &&
          (latLong.longitude <
              (latLongs[j].longitude - latLongs[i].longitude) *
                      (latLong.latitude - latLongs[i].latitude) /
                      (latLongs[j].latitude - latLongs[i].latitude) +
                  latLongs[i].longitude)) {
        result = !result;
      }
    }
    return result;
  }

  /**
   * Returns the distance between the given segment and point.
   * <p>
   * libGDX (Apache 2.0)
   */
  static double distanceSegmentPoint(double startX, double startY, double endX,
      double endY, double pointX, double pointY) {
    Mappoint nearest =
        nearestSegmentPoint(startX, startY, endX, endY, pointX, pointY);
    return sqrt(pow(nearest.x - pointX, 2) + pow(nearest.y - pointY, 2));
  }

  /**
   * Creates a new LatLong from a comma-separated string of coordinates in the order latitude, longitude. All
   * coordinate values must be in degrees.
   *
   * @param latLongString the string that describes the LatLong.
   * @return a new LatLong with the given coordinates.
   * @throws IllegalArgumentException if the string cannot be parsed or describes an invalid LatLong.
   */
//  static LatLong fromString(String latLongString) {
//    List<double> coordinates = parseCoordinateString(latLongString, 2);
//    return new LatLong(coordinates[0], coordinates[1]);
//  }

  /// Calculate the Euclidean distance between two LatLongs in degrees using the Pythagorean
  /// theorem.
  ///
  /// @param latLong1 first LatLong
  /// @param latLong2 second LatLong
  /// @return distance in degrees as a double
  static double euclideanDistance(ILatLong latLong1, ILatLong latLong2) {
    return sqrt(pow(latLong1.longitude - latLong2.longitude, 2) +
        pow(latLong1.latitude - latLong2.latitude, 2));
  }

  /**
   * Find if this way is closed.
   *
   * @return true if this way is closed, false otherwise.
   */
  static bool isClosedWay(List<ILatLong?> latLongs) {
    return euclideanDistance(
            latLongs[0] as LatLong, latLongs[latLongs.length - 1] as LatLong) <
        0.000000001;
  }

  /**
   * Converts a coordinate from microdegrees (degrees * 10^6) to degrees. No validation is performed.
   *
   * @param coordinate the coordinate in microdegrees (degrees * 10^6).
   * @return the coordinate in degrees.
   */
  static double microdegreesToDegrees(int coordinate) {
    return coordinate / CONVERSION_FACTOR;
  }

  /**
   * Returns a point on the segment nearest to the specified point.
   * <p>
   * libGDX (Apache 2.0)
   */
  static Mappoint nearestSegmentPoint(double startX, double startY, double endX,
      double endY, double pointX, double pointY) {
    double xDiff = endX - startX;
    double yDiff = endY - startY;
    double length2 = xDiff * xDiff + yDiff * yDiff;
    if (length2 == 0) return Mappoint(startX, startY);
    double t = ((pointX - startX) * (endX - startX) +
            (pointY - startY) * (endY - startY)) /
        length2;
    if (t < 0) return Mappoint(startX, startY);
    if (t > 1) return Mappoint(endX, endY);
    return Mappoint(startX + t * (endX - startX), startY + t * (endY - startY));
  }

  /**
   * Parses a given number of comma-separated coordinate values from the supplied string.
   *
   * @param coordinatesString   a comma-separated string of coordinate values.
   * @param numberOfCoordinates the expected number of coordinate values in the string.
   * @return the coordinate values in the order they have been parsed from the string.
   * @throws IllegalArgumentException if the string is invalid or does not contain the given number of coordinate values.
   */
//  static List<double> parseCoordinateString(String coordinatesString,
//      int numberOfCoordinates) {
//    StringTokenizer stringTokenizer = new StringTokenizer(
//        coordinatesString, DELIMITER, true);
//    bool isDelimiter = true;
//    List<String> tokens = new ArrayList<>(numberOfCoordinates);
//
//    while (stringTokenizer.hasMoreTokens()) {
//      String token = stringTokenizer.nextToken();
//      isDelimiter = !isDelimiter;
//      if (isDelimiter) {
//        continue;
//      }
//
//      tokens.add(token);
//    }
//
//    if (isDelimiter) {
//      throw new Exception(
//          "invalid coordinate delimiter: " + coordinatesString);
//    } else if (tokens.length != numberOfCoordinates) {
//      throw new Exception(
//          "invalid number of coordinate values: " + coordinatesString);
//    }
//
//    List<double> coordinates = new double[numberOfCoordinates];
//    for (int i = 0; i < numberOfCoordinates; ++i) {
//      coordinates[i] = double.parse(tokens.get(i));
//    }
//    return coordinates;
//  }

  /**
   * Calculates the zoom level that allows to display the {@link BoundingBox} on a view with the {@link Dimension} and
   * tile size.
   *
   * @param dimension   the {@link Dimension} of the view.
   * @param boundingBox the {@link BoundingBox} to display.
   * @param tileSize    the size of the tiles.
   * @return the zoom level that allows to display the {@link BoundingBox} on a view with the {@link Dimension} and
   * tile size.
   */
//  static int zoomForBounds(
//      Dimension dimension, BoundingBox boundingBox, int tileSize) {
//    int mapSize = MercatorProjection.getMapSize(0, tileSize);
//    double pixelXMax = MercatorProjection.longitudeToPixelXAtMapSize(
//        boundingBox.maxLongitude, mapSize);
//    double pixelXMin = MercatorProjection.longitudeToPixelXAtMapSize(
//        boundingBox.minLongitude, mapSize);
//    double zoomX =
//        -1 * log((pixelXMax - pixelXMin).abs() / dimension.width) / log(2);
//    double pixelYMax = MercatorProjection.latitudeToPixelYWithMapSize(
//        boundingBox.maxLatitude, mapSize);
//    double pixelYMin = MercatorProjection.latitudeToPixelYWithMapSize(
//        boundingBox.minLatitude, mapSize);
//    double zoomY =
//        -1 * log((pixelYMax - pixelYMin).abs() / dimension.height) / log(2);
//    int zoom = min(zoomX, zoomY).floor();
//    if (zoom < 0) {
//      return 0;
//    }
//    if (zoom > 255) {
//      return 255;
//    }
//    return zoom;
//  }

  LatLongUtils() {
    throw new Exception();
  }
}
