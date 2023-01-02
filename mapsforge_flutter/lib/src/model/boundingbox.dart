import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/projection/projection.dart';

import 'latlong.dart';

/// A BoundingBox represents an immutable set of two latitude and two longitude coordinates.
class BoundingBox {
  /**
   * Creates a new BoundingBox from a comma-separated string of coordinates in the order minLat, minLon, maxLat,
   * maxLon. All coordinate values must be in degrees.
   *
   * @param boundingBoxString the string that describes the BoundingBox.
   * @return a new BoundingBox with the given coordinates.
   * @throws IllegalArgumentException if the string cannot be parsed or describes an invalid BoundingBox.
   */
//  static BoundingBox fromString(String boundingBoxString) {
//    List<double> coordinates =
//        LatLongUtils.parseCoordinateString(boundingBoxString, 4);
//    return new BoundingBox(
//        coordinates[0], coordinates[1], coordinates[2], coordinates[3]);
//  }

  /// The maximum latitude coordinate of this BoundingBox in degrees.
  final double maxLatitude;

  /// The maximum longitude coordinate of this BoundingBox in degrees.
  final double maxLongitude;

  /// The minimum latitude coordinate of this BoundingBox in degrees.
  final double minLatitude;

  /// The minimum longitude coordinate of this BoundingBox in degrees.
  final double minLongitude;

  /**
   * @param minLatitude  the minimum latitude coordinate in degrees.
   * @param minLongitude the minimum longitude coordinate in degrees.
   * @param maxLatitude  the maximum latitude coordinate in degrees.
   * @param maxLongitude the maximum longitude coordinate in degrees.
   * @throws IllegalArgumentException if a coordinate is invalid.
   */
  const BoundingBox(
      this.minLatitude, this.minLongitude, this.maxLatitude, this.maxLongitude)
      : assert(minLatitude <= maxLatitude),
        assert(minLongitude <= maxLongitude);

  // {
  //   Projection.checkLatitude(minLatitude);
  //   Projection.checkLongitude(minLongitude);
  //   Projection.checkLatitude(maxLatitude);
  //   Projection.checkLongitude(maxLongitude);
  // }

  /**
   * @param latLongs the coordinates list.
   */
  static BoundingBox fromLatLongs(List<ILatLong> latLongs) {
    double minLatitude = double.infinity;
    double minLongitude = double.infinity;
    double maxLatitude = double.negativeInfinity;
    double maxLongitude = double.negativeInfinity;
    for (ILatLong latLong in latLongs) {
      double latitude = latLong.latitude;
      double longitude = latLong.longitude;

      minLatitude = min(minLatitude, latitude);
      minLongitude = min(minLongitude, longitude);
      maxLatitude = max(maxLatitude, latitude);
      maxLongitude = max(maxLongitude, longitude);
    }

    // Projection.checkLatitude(minLatitude);
    // Projection.checkLongitude(minLongitude);
    // Projection.checkLatitude(maxLatitude);
    // Projection.checkLongitude(maxLongitude);
    return BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }

  /**
   * @param latitude  the latitude coordinate in degrees.
   * @param longitude the longitude coordinate in degrees.
   * @return true if this BoundingBox contains the given coordinates, false otherwise.
   */
  bool contains(double latitude, double? longitude) {
    return this.minLatitude <= latitude &&
        this.maxLatitude >= latitude &&
        this.minLongitude <= longitude! &&
        this.maxLongitude >= longitude;
  }

  /**
   * @param latLong the LatLong whose coordinates should be checked.
   * @return true if this BoundingBox contains the given LatLong, false otherwise.
   */
  bool containsLatLong(ILatLong latLong) {
    return contains(latLong.latitude, latLong.longitude);
  }

  bool containsBoundingBox(BoundingBox box) {
    return contains(box.minLatitude, box.minLongitude) &&
        contains(box.maxLatitude, box.maxLongitude);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBox &&
          runtimeType == other.runtimeType &&
          maxLatitude == other.maxLatitude &&
          maxLongitude == other.maxLongitude &&
          minLatitude == other.minLatitude &&
          minLongitude == other.minLongitude &&
          intersectsArea == other.intersectsArea;

  @override
  int get hashCode =>
      maxLatitude.hashCode ^
      maxLongitude.hashCode ^
      minLatitude.hashCode ^
      minLongitude.hashCode ^
      intersectsArea.hashCode;

  /**
   * @param boundingBox the BoundingBox which this BoundingBox should be extended if it is larger
   * @return a BoundingBox that covers this BoundingBox and the given BoundingBox.
   */
  BoundingBox extendBoundingBox(BoundingBox boundingBox) {
    return new BoundingBox(
        min(this.minLatitude, boundingBox.minLatitude),
        min(this.minLongitude, boundingBox.minLongitude),
        max(this.maxLatitude, boundingBox.maxLatitude),
        max(this.maxLongitude, boundingBox.maxLongitude));
  }

  /**
   * Creates a BoundingBox extended up to coordinates (but does not cross date line/poles).
   *
   * @param latitude  up to the extension
   * @param longitude up to the extension
   * @return an extended BoundingBox or this (if contains coordinates)
   */
//  BoundingBox extendCoordinates(double latitude, double longitude) {
//    if (contains(latitude, longitude)) {
//      return this;
//    }
//
//    double minLat =
//        max(MercatorProjection.LATITUDE_MIN, min(this.minLatitude, latitude));
//    double minLon = max(-180, min(this.minLongitude, longitude));
//    double maxLat =
//        min(MercatorProjection.LATITUDE_MAX, max(this.maxLatitude, latitude));
//    double maxLon = min(180, max(this.maxLongitude, longitude));
//
//    return new BoundingBox(minLat, minLon, maxLat, maxLon);
//  }

  /**
   * Creates a BoundingBox extended up to <code>LatLong</code> (but does not cross date line/poles).
   *
   * @param latLong coordinates up to the extension
   * @return an extended BoundingBox or this (if contains coordinates)
   */
//  BoundingBox extendCoordinatesLatLong(LatLong latLong) {
//    return extendCoordinates(latLong.latitude, latLong.longitude);
//  }

  /**
   * Creates a BoundingBox that is a fixed degree amount larger on all sides (but does not cross date line/poles).
   *
   * @param verticalExpansion   degree extension (must be >= 0)
   * @param horizontalExpansion degree extension (must be >= 0)
   * @return an extended BoundingBox or this (if degrees == 0)
   */
//  BoundingBox extendDegrees(
//      double verticalExpansion, double horizontalExpansion) {
//    if (verticalExpansion == 0 && horizontalExpansion == 0) {
//      return this;
//    } else if (verticalExpansion < 0 || horizontalExpansion < 0) {
//      throw new Exception(
//          "BoundingBox extend operation does not accept negative values");
//    }
//
//    double minLat = max(
//        MercatorProjection.LATITUDE_MIN, this.minLatitude - verticalExpansion);
//    double minLon = max(-180, this.minLongitude - horizontalExpansion);
//    double maxLat = min(
//        MercatorProjection.LATITUDE_MAX, this.maxLatitude + verticalExpansion);
//    double maxLon = min(180, this.maxLongitude + horizontalExpansion);
//
//    return new BoundingBox(minLat, minLon, maxLat, maxLon);
//  }

  /**
   * Creates a BoundingBox that is a fixed margin factor larger on all sides (but does not cross date line/poles).
   *
   * @param margin extension (must be > 0)
   * @return an extended BoundingBox or this (if margin == 1)
   */
//  BoundingBox extendMargin(double margin) {
//    if (margin == 1) {
//      return this;
//    } else if (margin <= 0) {
//      throw new Exception(
//          "BoundingBox extend operation does not accept negative or zero values");
//    }
//
//    double verticalExpansion =
//        (this.getLatitudeSpan() * margin - this.getLatitudeSpan()) * 0.5;
//    double horizontalExpansion =
//        (this.getLongitudeSpan() * margin - this.getLongitudeSpan()) * 0.5;
//
//    double minLat = max(
//        MercatorProjection.LATITUDE_MIN, this.minLatitude - verticalExpansion);
//    double minLon = max(-180, this.minLongitude - horizontalExpansion);
//    double maxLat = min(
//        MercatorProjection.LATITUDE_MAX, this.maxLatitude + verticalExpansion);
//    double maxLon = min(180, this.maxLongitude + horizontalExpansion);
//
//    return new BoundingBox(minLat, minLon, maxLat, maxLon);
//  }

  /**
   * Creates a BoundingBox that is a fixed meter amount larger on all sides (but does not cross date line/poles).
   *
   * @param meters extension (must be >= 0)
   * @return an extended BoundingBox or this (if meters == 0)
   */
  BoundingBox extendMeters(int meters) {
    assert(meters >= 0);
    if (meters == 0) {
      return this;
    }

    double verticalExpansion = Projection.latitudeDistance(meters);
    double horizontalExpansion = Projection.longitudeDistance(
        meters, max(minLatitude.abs(), maxLatitude.abs()));

    double minLat =
        max(Projection.LATITUDE_MIN, this.minLatitude - verticalExpansion);
    double minLon =
        max(Projection.LONGITUDE_MIN, this.minLongitude - horizontalExpansion);
    double maxLat =
        min(Projection.LATITUDE_MAX, this.maxLatitude + verticalExpansion);
    double maxLon =
        min(Projection.LONGITUDE_MAX, this.maxLongitude + horizontalExpansion);

    return new BoundingBox(minLat, minLon, maxLat, maxLon);
  }

  /**
   * @return a new LatLong at the horizontal and vertical center of this BoundingBox.
   */
  LatLong getCenterPoint() {
    double latitudeOffset = (this.maxLatitude - this.minLatitude) / 2;
    double longitudeOffset = (this.maxLongitude - this.minLongitude) / 2;
    return new LatLong(
        this.minLatitude + latitudeOffset, this.minLongitude + longitudeOffset);
  }

  /**
   * @return the latitude span of this BoundingBox in degrees.
   */
  double getLatitudeSpan() {
    return this.maxLatitude - this.minLatitude;
  }

  /**
   * @return the longitude span of this BoundingBox in degrees.
   */
  double getLongitudeSpan() {
    return this.maxLongitude - this.minLongitude;
  }

  /**
   * Computes the coordinates of this bounding box relative to a tile.
   *
   * @param tile the tile to compute the relative position for.
   * @return rectangle giving the relative position.
   */
//  Rectangle getPositionRelativeToTile(Tile tile) {
//    Mappoint upperLeft = MercatorProjection.getPixelRelativeToTile(
//        new LatLong(this.maxLatitude, minLongitude), tile);
//    Mappoint lowerRight = MercatorProjection.getPixelRelativeToTile(
//        new LatLong(this.minLatitude, maxLongitude), tile);
//    return new Rectangle(upperLeft.x, upperLeft.y, lowerRight.x, lowerRight.y);
//  }

  /// @param boundingBox the BoundingBox which should be checked for intersection with this BoundingBox.
  /// @return true if this BoundingBox intersects with the given BoundingBox, false otherwise.
  bool intersects(BoundingBox boundingBox) {
    if (this == boundingBox) {
      return true;
    }

    return this.maxLatitude >= boundingBox.minLatitude &&
        this.maxLongitude >= boundingBox.minLongitude &&
        this.minLatitude <= boundingBox.maxLatitude &&
        this.minLongitude <= boundingBox.maxLongitude;
  }

  /**
   * Returns if an area built from the latLongs intersects with a bias towards
   * returning true.
   * The method returns fast if any of the points lie within the bbox. If none of the points
   * lie inside the box, it constructs the outer bbox for all the points and tests for intersection
   * (so it is possible that the area defined by the points does not actually intersect)
   *
   * @param latLongs the points that define an area
   * @return false if there is no intersection, true if there could be an intersection
   */
  bool intersectsArea(List<List<ILatLong>> latLongs) {
    if (latLongs.length == 0 || latLongs[0].length == 0) {
      return false;
    }
    for (List<ILatLong> outer in latLongs) {
      for (ILatLong latLong in outer) {
        if (this.containsLatLong(latLong)) {
          // if any of the points is inside the bbox return early
          return true;
        }
      }
    }

    // no fast solution, so accumulate boundary points
    double tmpMinLat = latLongs[0][0].latitude;
    double tmpMinLon = latLongs[0][0].longitude;
    double tmpMaxLat = latLongs[0][0].latitude;
    double tmpMaxLon = latLongs[0][0].longitude;

    for (List<ILatLong> outer in latLongs) {
      for (ILatLong latLong in outer) {
        tmpMinLat = min(tmpMinLat, latLong.latitude);
        tmpMaxLat = max(tmpMaxLat, latLong.latitude);
        tmpMinLon = min(tmpMinLon, latLong.longitude);
        tmpMaxLon = max(tmpMaxLon, latLong.longitude);
      }
    }
    return this.intersects(
        new BoundingBox(tmpMinLat, tmpMinLon, tmpMaxLat, tmpMaxLon));
  }

  @override
  String toString() {
    return 'BoundingBox{maxLatitude: $maxLatitude, maxLongitude: $maxLongitude, minLatitude: $minLatitude, minLongitude: $minLongitude}';
  }
}
