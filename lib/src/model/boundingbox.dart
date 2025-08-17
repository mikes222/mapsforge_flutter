import 'dart:math' as Math;
import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/projection/projection.dart';

/// A BoundingBox represents an immutable set of two latitude and two longitude coordinates.
class BoundingBox {
  /// The maximum latitude coordinate of this BoundingBox in degrees.
  final double maxLatitude;

  /// The maximum longitude coordinate of this BoundingBox in degrees.
  final double maxLongitude;

  /// The minimum latitude coordinate of this BoundingBox in degrees.
  final double minLatitude;

  /// The minimum longitude coordinate of this BoundingBox in degrees.
  final double minLongitude;

  /// @param minLatitude  the minimum latitude coordinate in degrees.
  /// @param minLongitude the minimum longitude coordinate in degrees.
  /// @param maxLatitude  the maximum latitude coordinate in degrees.
  /// @param maxLongitude the maximum longitude coordinate in degrees.
  /// @throws IllegalArgumentException if a coordinate is invalid.
  const BoundingBox(this.minLatitude, this.minLongitude, this.maxLatitude, this.maxLongitude)
      : assert(minLatitude <= maxLatitude),
        assert(minLongitude <= maxLongitude);

  /// @param latLongs the coordinates list.
  factory BoundingBox.fromLatLongs(List<ILatLong> latLongs) {
    assert(latLongs.isNotEmpty);
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

  factory BoundingBox.from2(ILatLong first, ILatLong second) {
    return BoundingBox(Math.min(first.latitude, second.latitude), Math.min(first.longitude, second.longitude), Math.max(first.latitude, second.latitude),
        Math.max(first.longitude, second.longitude));
  }

  /// @param latitude  the latitude coordinate in degrees.
  /// @param longitude the longitude coordinate in degrees.
  /// @return true if this BoundingBox contains the given coordinates, false otherwise.
  bool contains(double latitude, double longitude) {
    return this.minLatitude <= latitude && this.maxLatitude >= latitude && this.minLongitude <= longitude && this.maxLongitude >= longitude;
  }

  /// @param latLong the LatLong whose coordinates should be checked.
  /// @return true if this BoundingBox contains the given LatLong, false otherwise.
  bool containsLatLong(ILatLong latLong) {
    return contains(latLong.latitude, latLong.longitude);
  }

  /// @param box the BoundingBox whose coordinates should be checked.
  /// @return true if this BoundingBox contains the given BoundingBox completely, false otherwise.
  bool containsBoundingBox(BoundingBox box) {
    return contains(box.minLatitude, box.minLongitude) && contains(box.maxLatitude, box.maxLongitude);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBox &&
          runtimeType == other.runtimeType &&
          maxLatitude == other.maxLatitude &&
          maxLongitude == other.maxLongitude &&
          minLatitude == other.minLatitude &&
          minLongitude == other.minLongitude;

  @override
  int get hashCode => maxLatitude.hashCode ^ maxLongitude.hashCode ^ minLatitude.hashCode ^ minLongitude.hashCode;

  /// @param boundingBox the BoundingBox which this BoundingBox should be extended if it is larger
  /// @return a BoundingBox that covers this BoundingBox and the given BoundingBox.
  BoundingBox extendBoundingBox(BoundingBox boundingBox) {
    return BoundingBox(min(this.minLatitude, boundingBox.minLatitude), min(this.minLongitude, boundingBox.minLongitude),
        max(this.maxLatitude, boundingBox.maxLatitude), max(this.maxLongitude, boundingBox.maxLongitude));
  }

  ILatLong getLeftUpper() => LatLong(maxLatitude, minLongitude);

  ILatLong getLeftLower() => LatLong(minLatitude, minLongitude);

  ILatLong getRightUpper() => LatLong(maxLatitude, maxLongitude);

  ILatLong getRightLower() => LatLong(minLatitude, maxLongitude);

  ILatLong getTopCenter() => LatLong(maxLatitude, minLongitude + (maxLongitude - minLongitude) / 2);

  ILatLong getBottomCenter() => LatLong(minLatitude, minLongitude + (maxLongitude - minLongitude) / 2);

  ILatLong getLeftCenter() => LatLong(minLatitude + (maxLatitude - minLatitude) / 2, minLongitude);

  ILatLong getRightCenter() => LatLong(minLatitude + (maxLatitude - minLatitude) / 2, maxLongitude);

  ILatLong getLeftUpperRotate(int steps) {
    switch (steps) {
      case -1:
      case 0:
        return getLeftUpper();
      case 1:
        return getRightUpper();
      case 2:
        return getRightLower();
      case 3:
        return getLeftLower();
      default:
        throw Exception("step $steps out of range");
    }
  }

  ILatLong getRightUpperRotate(int steps) {
    switch (steps) {
      case -1:
      case 0:
        return getRightUpper();
      case 1:
        return getRightLower();
      case 2:
        return getLeftLower();
      case 3:
        return getLeftUpper();
      default:
        throw Exception("step $steps out of range");
    }
  }

  ILatLong getRightLowerRotate(int steps) {
    switch (steps) {
      case -1:
      case 0:
        return getRightLower();
      case 1:
        return getLeftLower();
      case 2:
        return getLeftUpper();
      case 3:
        return getRightUpper();
      default:
        throw Exception("step $steps out of range");
    }
  }

  ILatLong getLeftLowerRotate(int steps) {
    switch (steps) {
      case -1:
      case 0:
        return getLeftLower();
      case 1:
        return getLeftUpper();
      case 2:
        return getRightUpper();
      case 3:
        return getRightLower();
      default:
        throw Exception("step $steps out of range");
    }
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
  BoundingBox extendMargin(double margin) {
    assert(margin >= 1);
    if (margin == 1) {
      return this;
    }

    double verticalExpansion = (this.getLatitudeSpan() * margin - this.getLatitudeSpan()) * 0.5;
    double horizontalExpansion = (this.getLongitudeSpan() * margin - this.getLongitudeSpan()) * 0.5;

    double minLat = max(Projection.LATITUDE_MIN, this.minLatitude - verticalExpansion);
    double minLon = max(-180, this.minLongitude - horizontalExpansion);
    double maxLat = min(Projection.LATITUDE_MAX, this.maxLatitude + verticalExpansion);
    double maxLon = min(180, this.maxLongitude + horizontalExpansion);

    return BoundingBox(minLat, minLon, maxLat, maxLon);
  }

  /// Creates a BoundingBox that is a fixed meter amount larger on all sides (but does not cross date line/poles).
  ///
  /// @param meters extension (must be >= 0)
  /// @return an extended BoundingBox or this (if meters == 0)
  BoundingBox extendMeters(int meters) {
    assert(meters >= 0);
    if (meters == 0) {
      return this;
    }

    double verticalExpansion = Projection.latitudeDistance(meters);
    double horizontalExpansion = Projection.longitudeDistance(meters, max(minLatitude.abs(), maxLatitude.abs()));

    double minLat = max(Projection.LATITUDE_MIN, this.minLatitude - verticalExpansion);
    double minLon = max(Projection.LONGITUDE_MIN, this.minLongitude - horizontalExpansion);
    double maxLat = min(Projection.LATITUDE_MAX, this.maxLatitude + verticalExpansion);
    double maxLon = min(Projection.LONGITUDE_MAX, this.maxLongitude + horizontalExpansion);

    return BoundingBox(minLat, minLon, maxLat, maxLon);
  }

  /**
   * @return a new LatLong at the horizontal and vertical center of this BoundingBox.
   */
  LatLong getCenterPoint() {
    double latitudeOffset = (this.maxLatitude - this.minLatitude) / 2;
    double longitudeOffset = (this.maxLongitude - this.minLongitude) / 2;
    return new LatLong(this.minLatitude + latitudeOffset, this.minLongitude + longitudeOffset);
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

  /// Returns true if the rectange overlaps with the given rectangle. The
  /// rectangles intersect if their four edges overlap at least at one point.
  /// To determine an intersection, all four conditions must be met.
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
    return this.intersects(new BoundingBox(tmpMinLat, tmpMinLon, tmpMaxLat, tmpMaxLon));
  }

  /// Checks if a line intersects with the rectangle.
  ///
  /// @param lineStart Der Startpunkt der Linie.
  /// @param lineEnd Der Endpunkt der Linie.
  /// @param rectangle Das Rechteck, das auf Überschneidung geprüft werden soll.
  /// @return `true`, wenn die Linie das Rechteck überschneidet oder berührt, andernfalls `false`.
  bool intersectsLine(ILatLong lineStart, ILatLong lineEnd) {
    // 1. Überprüfe, ob einer der Linienendpunkte innerhalb des Rechtecks liegt.
    if (this.containsLatLong(lineStart) || this.containsLatLong(lineEnd)) {
      return true;
    }

    // 2. Definiere die vier Liniensegmente des Rechtecks.
    ILatLong topLeft = LatLong(maxLatitude, minLongitude);
    ILatLong topRight = LatLong(maxLatitude, maxLongitude);
    ILatLong bottomRight = LatLong(minLatitude, maxLongitude);
    ILatLong bottomLeft = LatLong(minLatitude, minLongitude);

    // 3. Überprüfe, ob die Linie eines der Rechtecksegmente schneidet.
    bool topIntersects = LatLongUtils.doLinesIntersect(lineStart, lineEnd, topLeft, topRight);
    if (topIntersects) return true;
    bool rightIntersects = LatLongUtils.doLinesIntersect(lineStart, lineEnd, topRight, bottomRight);
    if (rightIntersects) return true;
    bool bottomIntersects = LatLongUtils.doLinesIntersect(lineStart, lineEnd, bottomRight, bottomLeft);
    if (bottomIntersects) return true;
    bool leftIntersects = LatLongUtils.doLinesIntersect(lineStart, lineEnd, bottomLeft, topLeft);
    if (leftIntersects) return true;
    return false;
  }

  @override
  String toString() {
    return 'BoundingBox{minLatitude: ${minLatitude.toStringAsFixed(6)}, minLongitude: ${minLongitude.toStringAsFixed(6)}, maxLatitude: ${maxLatitude.toStringAsFixed(6)}, maxLongitude: ${maxLongitude.toStringAsFixed(6)}}';
  }
}
