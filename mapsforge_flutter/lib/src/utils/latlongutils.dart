import 'dart:math';

import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';

import '../model/latlong.dart';

class LatLongUtils {
  /**
   * The equatorial radius as defined by the <a href="http://en.wikipedia.org/wiki/World_Geodetic_System">WGS84
   * ellipsoid</a>. WGS84 is the reference coordinate system used by the Global Positioning System.
   */
  static final double EQUATORIAL_RADIUS = 6378137.0;

  /**
   * The flattening factor of the earth's ellipsoid is required for distance computation.
   */
  static final double INVERSE_FLATTENING = 298.257223563;

  /**
   * Polar radius of earth is required for distance computation.
   */
  static final double POLAR_RADIUS = 6356752.3142;

  /**
   * Maximum possible latitude coordinate.
   */
  static final double LATITUDE_MAX = 90;

  /**
   * Minimum possible latitude coordinate.
   */
  static final double LATITUDE_MIN = -LATITUDE_MAX;

  /**
   * Maximum possible longitude coordinate.
   */
  static final double LONGITUDE_MAX = 180;

  /**
   * Minimum possible longitude coordinate.
   */
  static final double LONGITUDE_MIN = -LONGITUDE_MAX;

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
      if ((latLongs[i].latitude > latLong.latitude) != (latLongs[j].latitude > latLong.latitude) &&
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
   * Converts a coordinate from degrees to microdegrees (degrees * 10^6). No validation is performed.
   *
   * @param coordinate the coordinate in degrees.
   * @return the coordinate in microdegrees (degrees * 10^6).
   */
  static int degreesToMicrodegrees(double coordinate) {
    return (coordinate * CONVERSION_FACTOR).floor();
  }

  /**
   * Returns the destination point from this point having travelled the given distance on the
   * given initial bearing (bearing normally varies around path followed).
   *
   * @param start    the start point
   * @param distance the distance travelled, in same units as earth radius (default: meters)
   * @param bearing  the initial bearing in degrees from north
   * @return the destination point
   * @see <a href="http://www.movable-type.co.uk/scripts/latlon.js">latlon.js</a>
   */
  static LatLong destinationPoint(LatLong start, double distance, double bearing) {
    double theta = toRadians(bearing);
    double delta = distance / EQUATORIAL_RADIUS; // angular distance in radians

    double phi1 = toRadians(start.latitude);
    double lambda1 = toRadians(start.longitude);

    double phi2 = asin(sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(theta));
    double lambda2 = lambda1 + atan2(sin(theta) * sin(delta) * cos(phi1), cos(delta) - sin(phi1) * sin(phi2));

    return new LatLong(toDegrees(phi2), toDegrees(lambda2));
  }

  /**
   * Calculate the Euclidean distance between two LatLongs in degrees using the Pythagorean
   * theorem.
   *
   * @param latLong1 first LatLong
   * @param latLong2 second LatLong
   * @return distance in degrees as a double
   */
  static double euclideanDistance(LatLong latLong1, LatLong latLong2) {
    return sqrt(pow(latLong1.longitude - latLong2.longitude, 2) + pow(latLong1.latitude - latLong2.latitude, 2));
  }

  /**
   * Returns the distance between the given segment and point.
   * <p>
   * libGDX (Apache 2.0)
   */
  static double distanceSegmentPoint(double startX, double startY, double endX, double endY, double pointX, double pointY) {
    Point nearest = nearestSegmentPoint(startX, startY, endX, endY, pointX, pointY);
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

  /**
   * Find if this way is closed.
   *
   * @return true if this way is closed, false otherwise.
   */
  static bool isClosedWay(List<ILatLong> latLongs) {
    return euclideanDistance(latLongs[0], latLongs[latLongs.length - 1]) < 0.000000001;
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
    return (meters * 360) / (2 * pi * EQUATORIAL_RADIUS * cos(toRadians(latitude)));
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
  static Point nearestSegmentPoint(double startX, double startY, double endX, double endY, double pointX, double pointY) {
    double xDiff = endX - startX;
    double yDiff = endY - startY;
    double length2 = xDiff * xDiff + yDiff * yDiff;
    if (length2 == 0) return new Point(startX, startY);
    double t = ((pointX - startX) * (endX - startX) + (pointY - startY) * (endY - startY)) / length2;
    if (t < 0) return new Point(startX, startY);
    if (t > 1) return new Point(endX, endY);
    return new Point(startX + t * (endX - startX), startY + t * (endY - startY));
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
   * Calculate the spherical distance between two LatLongs in meters using the Haversine
   * formula.
   * <p/>
   * This calculation is done using the assumption, that the earth is a sphere, it is not
   * though. If you need a higher precision and can afford a longer execution time you might
   * want to use vincentyDistance.
   *
   * @param latLong1 first LatLong
   * @param latLong2 second LatLong
   * @return distance in meters as a double
   */
  static double sphericalDistance(LatLong latLong1, LatLong latLong2) {
    double dLat = toRadians(latLong2.latitude - latLong1.latitude);
    double dLon = toRadians(latLong2.longitude - latLong1.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(toRadians(latLong1.latitude)) * cos(toRadians(latLong2.latitude)) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return c * LatLongUtils.EQUATORIAL_RADIUS;
  }

  /**
   * @param latitude the latitude coordinate in degrees which should be validated.
   * @return the latitude value
   * @throws IllegalArgumentException if the latitude coordinate is invalid or {@link Double#NaN}.
   */
  static double validateLatitude(double latitude) {
    if (latitude == double.nan || latitude < LATITUDE_MIN || latitude > LATITUDE_MAX) {
      throw new Exception("invalid latitude: $latitude");
    }
    return latitude;
  }

  /**
   * @param longitude the longitude coordinate in degrees which should be validated.
   * @return the longitude value
   * @throws IllegalArgumentException if the longitude coordinate is invalid or {@link Double#NaN}.
   */
  static double validateLongitude(double longitude) {
    if (longitude == double.nan || longitude < LONGITUDE_MIN || longitude > LONGITUDE_MAX) {
      throw new Exception("invalid longitude: $longitude");
    }
    return longitude;
  }

  /**
   * Calculates geodetic distance between two LatLongs using Vincenty inverse formula
   * for ellipsoids. This is very accurate but consumes more resources and time than the
   * sphericalDistance method.
   * <p/>
   * Adaptation of Chriss Veness' JavaScript Code on
   * http://www.movable-type.co.uk/scripts/latlong-vincenty.html
   * <p/>
   * Paper: Vincenty inverse formula - T Vincenty, "Direct and Inverse Solutions of Geodesics
   * on the Ellipsoid with application of nested equations", Survey Review, vol XXII no 176,
   * 1975 (http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf)
   *
   * @param latLong1 first LatLong
   * @param latLong2 second LatLong
   * @return distance in meters between points as a double
   */
  static double vincentyDistance(LatLong latLong1, LatLong latLong2) {
    double f = 1 / LatLongUtils.INVERSE_FLATTENING;
    double L = toRadians(latLong2.getLongitude() - latLong1.getLongitude());
    double U1 = atan((1 - f) * tan(toRadians(latLong1.getLatitude())));
    double U2 = atan((1 - f) * tan(toRadians(latLong2.getLatitude())));
    double sinU1 = sin(U1), cosU1 = cos(U1);
    double sinU2 = sin(U2), cosU2 = cos(U2);

    double lambda = L, lambdaP, iterLimit = 100;

    double cosSqAlpha = 0, sinSigma = 0, cosSigma = 0, cos2SigmaM = 0, sigma = 0, sinLambda = 0, sinAlpha = 0, cosLambda = 0;
    do {
      sinLambda = sin(lambda);
      cosLambda = cos(lambda);
      sinSigma = sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) +
          (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) * (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
      if (sinSigma == 0) return 0; // co-incident points
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = atan2(sinSigma, cosSigma);
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1 - sinAlpha * sinAlpha;
      if (cosSqAlpha != 0) {
        cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
      } else {
        cos2SigmaM = 0;
      }
      double C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
      lambdaP = lambda;
      lambda = L + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    } while ((lambda - lambdaP).abs() > 1e-12 && --iterLimit > 0);

    if (iterLimit == 0) return 0; // formula failed to converge

    double uSq =
        cosSqAlpha * (pow(LatLongUtils.EQUATORIAL_RADIUS, 2) - pow(LatLongUtils.POLAR_RADIUS, 2)) / pow(LatLongUtils.POLAR_RADIUS, 2);
    double A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    double B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
    double deltaSigma = B *
        sinSigma *
        (cos2SigmaM +
            B /
                4 *
                (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                    B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)));
    double s = LatLongUtils.POLAR_RADIUS * A * (sigma - deltaSigma);

    return s;
  }

  static double toRadians(double var0) {
    return var0 / 180.0 * 3.141592653589793;
  }

  static double toDegrees(double var0) {
    return var0 * 180.0 / 3.141592653589793;
  }

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
