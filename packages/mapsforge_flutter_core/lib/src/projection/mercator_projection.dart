import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/src/projection/scalefactor.dart';

/// Web Mercator projection implementation for converting between geographic and tile coordinates.
///
/// This class implements the standard Web Mercator projection (EPSG:3857) used by most
/// web mapping services. It provides conversions between:
/// - Geographic coordinates (latitude/longitude) and tile coordinates (tileX/tileY)
/// - Support for different zoom levels with scalefactor-based calculations
/// - Boundary box calculations for tiles and tile ranges
///
/// Key features:
/// - Efficient tile coordinate calculations
/// - Proper handling of world boundaries and edge cases
/// - Cached scalefactor for performance
/// - Dateline crossing fixes for boundary calculations
class MercatorProjection implements Projection {
  /// The scale factor for this projection, derived from the zoom level.
  ///
  /// Scale factor = 2^zoomLevel, where:
  /// - Zoom level 0: scalefactor = 1 (whole world in 1 tile)
  /// - Zoom level 1: scalefactor = 2 (world in 2x2 tiles)
  /// - Zoom level n: scalefactor = 2^n (world in 2^n x 2^n tiles)
  final Scalefactor _scalefactor;

  late final int _maxTileCount;

  MercatorProjection.fromZoomlevel(int zoomlevel) : _scalefactor = Scalefactor.fromZoomlevel(zoomlevel) {
    //_mapSize = _mapSizeWithScaleFactor(_scaleFactor.scalefactor);
    _maxTileCount = _scalefactor.scalefactor.floor();
  }

  MercatorProjection.fromScalefactor(double scaleFactor) : _scalefactor = Scalefactor.fromScalefactor(scaleFactor) {
    //_mapSize = _mapSizeWithScaleFactor(_scaleFactor);
    _maxTileCount = Scalefactor.zoomlevelToScalefactor(_scalefactor.zoomlevel).floor();
  }

  Scalefactor get scalefactor => _scalefactor;

  /// @param scaleFactor the scale factor for which the size of the world map should be returned.
  /// @return the horizontal and vertical size of the map in pixel at the given scale.
  /// @throws IllegalArgumentException if the given scale factor is < 1
  // double _mapSizeWithScaleFactor(double scaleFactor) {
  //   assert(scaleFactor >= 1);
  //   return (tileSize.toDouble() * (pow(2, Projection.scaleFactorToZoomLevel(scaleFactor))));
  // }

  /// Converts a longitude coordinate to the corresponding tile X number.
  ///
  /// Handles edge cases at the world boundaries (±180°) and ensures
  /// the result is within valid tile coordinate range.
  ///
  /// [longitude] The longitude coordinate in degrees (-180 to +180)
  /// Returns the tile X coordinate (0 to scalefactor-1)
  @override
  int longitudeToTileX(double longitude) {
    if (longitude >= 180) {
      return _maxTileCount - 1;
    }
    if (longitude <= -180) {
      return 0;
    }
    int result = ((longitude + 180) / 360 * _scalefactor.scalefactor).floor();
    return result;
  }

  /// Converts a tile X coordinate to the corresponding longitude (western edge).
  ///
  /// Returns the longitude of the western (left) edge of the specified tile.
  ///
  /// [tileX] The tile X coordinate to convert
  /// Returns the longitude in degrees of the tile's western boundary
  @override
  double tileXToLongitude(int tileX) {
    assert(tileX >= 0);
    // allow one more so that we can find the end of the tile from the left
    assert(tileX <= _maxTileCount, "$tileX > ${_maxTileCount} of zoomlevel ${scalefactor.zoomlevel}");
    double result = (tileX / _scalefactor.scalefactor * 360 - 180);
    return result;
    //return pixelXToLongitude(tileX * tileSize.toDouble());
  }

  /// Converts a tile Y coordinate to the corresponding latitude (northern edge).
  ///
  /// Returns the latitude of the northern (top) edge of the specified tile.
  /// Uses inverse Mercator projection formulas.
  ///
  /// [tileY] The tile Y coordinate to convert
  /// Returns the latitude in degrees of the tile's northern boundary
  @override
  double tileYToLatitude(int tileY) {
    assert(tileY >= 0);
    // allow one more so that we can find the end of the tile from the top
    assert(tileY <= _maxTileCount, "$tileY > ${_maxTileCount} of zoomlevel ${scalefactor.zoomlevel}");
    const double pi2 = 2 * pi;
    const double pi360 = 360 / pi;
    double y = 0.5 - (tileY / _scalefactor.scalefactor);
    return 90 - pi360 * atan(exp(-y * pi2));
  }

  /// Converts a latitude coordinate to the corresponding tile Y number.
  ///
  /// Handles edge cases at the poles (±90°) and uses Mercator projection
  /// formulas to calculate the correct tile coordinate.
  ///
  /// [latitude] The latitude coordinate in degrees (-90 to +90)
  /// Returns the tile Y coordinate (0 to scalefactor-1)
  @override
  int latitudeToTileY(double latitude) {
    if (latitude >= 90) {
      return 0;
    }
    if (latitude <= -90) {
      return _maxTileCount - 1;
    }
    const double pi180 = pi / 180;
    const double pi4 = 4 * pi;
    double sinLatitude = sin(latitude * pi180);
    // exceptions for 90 and -90 degrees
    if (sinLatitude == 1.0) return 0;
    if (sinLatitude == -1.0) return _maxTileCount - 1;
    double tileY = (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / pi4);
    // print(
    //     "tileY: $tileY, sinLat: $sinLatitude, log: ${log((1 + sinLatitude) / (1 - sinLatitude))}");
    int result = (tileY * _maxTileCount).floor();
    //print("Mercator: ${tileY * _scalefactor.scalefactor}");
    // seems with Latitude boundingBox.maxLatitude we get -1.5543122344752192e-15 so correct it to 0
    if (result < 0) return 0;
    if (result >= _maxTileCount) return _maxTileCount - 1;
    return result;
  }

  /// Calculates the geographic bounding box for a single tile.
  ///
  /// Returns the latitude/longitude boundaries that define the geographic
  /// area covered by the specified tile. Includes fixes for dateline crossing.
  ///
  /// [tile] The tile to calculate boundaries for
  /// Returns the BoundingBox in geographic coordinates
  BoundingBox boundingBoxOfTile(Tile tile) {
    double minLatitude = max(Projection.LATITUDE_MIN, tileYToLatitude(tile.tileY + 1));
    double minLongitude = max(Projection.LONGITUDE_MIN, tileXToLongitude(tile.tileX));
    double maxLatitude = min(Projection.LATITUDE_MAX, tileYToLatitude(tile.tileY));
    double maxLongitude = min(Projection.LONGITUDE_MAX, tileXToLongitude(tile.tileX + 1));
    if (maxLongitude == -180) {
      // fix for dateline crossing, where the right tile starts at -180 and causes an invalid bbox
      maxLongitude = 180;
    }
    return BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }

  BoundingBox boundingBoxOfTiles(Tile upperLeft, Tile lowerRight) {
    assert(upperLeft.zoomLevel == lowerRight.zoomLevel);
    assert(upperLeft.tileY <= lowerRight.tileY);
    assert(upperLeft.tileX <= lowerRight.tileX);
    double minLatitude = max(Projection.LATITUDE_MIN, tileYToLatitude(lowerRight.tileY + 1));
    double minLongitude = max(Projection.LONGITUDE_MIN, tileXToLongitude(upperLeft.tileX));
    double maxLatitude = min(Projection.LATITUDE_MAX, tileYToLatitude(upperLeft.tileY));
    double maxLongitude = min(Projection.LONGITUDE_MAX, tileXToLongitude(lowerRight.tileX + 1));
    if (maxLongitude == -180) {
      // fix for dateline crossing, where the right tile starts at -180 and causes an invalid bbox
      maxLongitude = 180;
    }
    return BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }

  BoundingBox boundingBoxOfTileNumbers(int top, int left, int bottom, int right) {
    assert(top <= bottom);
    assert(left <= right);
    double minLatitude = max(Projection.LATITUDE_MIN, tileYToLatitude(bottom + 1));
    double minLongitude = max(Projection.LONGITUDE_MIN, tileXToLongitude(left));
    double maxLatitude = min(Projection.LATITUDE_MAX, tileYToLatitude(top));
    double maxLongitude = min(Projection.LONGITUDE_MAX, tileXToLongitude(right + 1));
    if (maxLongitude == -180) {
      // fix for dateline crossing, where the right tile starts at -180 and causes an invalid bbox
      maxLongitude = 180;
    }
    return BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }
}
