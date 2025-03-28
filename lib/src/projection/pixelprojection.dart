import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/projection/scalefactor.dart';
import 'package:mapsforge_flutter/src/utils/mapsforge_constants.dart';

import '../model/relative_mappoint.dart';

class PixelProjection extends MercatorProjection {
  /// the size of a tile  in mappixel. Each tile has the same width and height.
  final double tileSize;

  ///
  /// the size of the whole map in mappixel. At scalefactor 1 (or zoomLevel 0)
  /// the _mapSize is equal to the tileSize.
  ///
  late int _mapSize;

  static final Map<String, double> _pixelDiffCache = {};

  PixelProjection(int zoomLevel)
      : tileSize = MapsforgeConstants().tileSize,
        super.fromZoomlevel(zoomLevel) {
    _mapSize = _mapSizeWithScaleFactor();
  }

  /// returns the number of pixel for the whole map at a given scalefactor
  int _mapSizeWithScaleFactor() {
    return (tileSize * scalefactor.scalefactor).round();
  }

  /// Converts a pixel X coordinate to the tile X number.
  ///
  /// @param pixelX    the pixel X coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile X number.
  int pixelXToTileX(double pixelX) {
    assert(pixelX >= 0);
    assert(pixelX <= _mapSize);
    return min(pixelX / tileSize, scalefactor.scalefactor - 1).floor();
  }

  /// Converts a pixel Y coordinate to the tile Y number.
  ///
  /// @param pixelY    the pixel Y coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile Y number.
  int pixelYToTileY(double pixelY) {
    assert(pixelY >= 0);
    assert(pixelY <= _mapSize);
    return min(pixelY / tileSize, scalefactor.scalefactor - 1).floor();
  }

  /// Converts a latitude coordinate (in degrees) to a pixel Y coordinate at a certain zoom level.
  ///
  /// @param latitude  the latitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the pixel Y coordinate of the latitude value.
  double latitudeToPixelY(double latitude) {
    const double pi180 = pi / 180;
    const double pi4 = 4 * pi;
    double sinLatitude = sin(latitude * pi180);
// FIXME improve this formula so that it works correctly without the clipping
    double pixelY = (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / pi4) * _mapSize;
    return min(max(0, pixelY), _mapSize.toDouble());
  }

  /// Converts a pixel Y coordinate at a certain map size to a latitude coordinate.
  ///
  /// @param pixelY  the pixel Y coordinate that should be converted.
  /// @param mapSize precomputed size of map.
  /// @return the latitude value of the pixel Y coordinate.
  /// @throws IllegalArgumentException if the given pixelY coordinate is invalid.
  double pixelYToLatitude(double pixelY) {
    pixelY = min(max(0, pixelY), _mapSize.toDouble());
    assert(pixelY >= 0);
    assert(pixelY <= _mapSize);
    const double pi2 = 2 * pi;
    const double pi360 = 360 / pi;
    double y = 0.5 - (pixelY / _mapSize);
    return 90 - pi360 * atan(exp(-y * pi2));
  }

  ILatLong pixelToLatLong(double pixelX, double pixelY) {
    return LatLong(pixelYToLatitude(pixelY), pixelXToLongitude(pixelX));
  }

  /// Converts a longitude coordinate (in degrees) to a pixel X coordinate at a certain zoom level.
  ///
  /// @param longitude the longitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @param tileSize  the tile size
  /// @return the pixel X coordinate of the longitude value.
  double longitudeToPixelX(double longitude) {
    return (longitude + 180) / 360 * _mapSize;
  }

  /// Converts a pixel X coordinate at a certain map size to a longitude coordinate.
  ///
  /// @param pixelX  the pixel X coordinate that should be converted.
  /// @param mapSize precomputed size of map.
  /// @return the longitude value of the pixel X coordinate.
  /// @throws IllegalArgumentException if the given pixelX coordinate is invalid.
  double pixelXToLongitude(double pixelX) {
    pixelX = min(max(0, pixelX), _mapSize.toDouble());
    assert(pixelX >= 0);
    assert(pixelX <= _mapSize);
    return 360 * ((pixelX / _mapSize) - 0.5);
  }

  double latitudeDiffPerPixel(double latitude, double pixelDiff) {
    String key = "${latitude.round()}_$pixelDiff";
    double? result = _pixelDiffCache[key];
    if (result == null) {
      double pixelY = latitudeToPixelY(latitude);
      double latitude2 = pixelYToLatitude(pixelY - pixelDiff);
      result = (latitude2 - latitude).abs();
      _pixelDiffCache[key] = result;
    }
    return result;
  }

  /// Calculates the absolute pixel position for a map size and tile size
  ///
  /// @param latLong the geographic position.
  /// @param mapSize precomputed size of map.
  /// @return the absolute pixel coordinates (for world)
  Mappoint latLonToPixel(ILatLong latLong) {
    return Mappoint(longitudeToPixelX(latLong.longitude), latitudeToPixelY(latLong.latitude));
  }

  /// Calculates the absolute pixel position for a tile and tile size relative to origin
  ///
  /// @param latLong the geographic position.
  /// @param tile    tile
  /// @return the relative pixel position to the origin values (e.g. for a tile)
  RelativeMappoint pixelRelativeToTile(ILatLong latLong, Tile tile) {
    Mappoint mappoint = latLonToPixel(latLong);
    Mappoint tilePoint = getLeftUpper(tile);
    return mappoint.offset(-tilePoint.x, -tilePoint.y);
  }

  /// Calculates the absolute pixel position for a tile and tile size relative to origin
  ///
  /// @param latLong the geographic position.
  /// @param tile    tile
  /// @return the relative pixel position to the origin values (e.g. for a tile)
  RelativeMappoint pixelRelativeToLeftUpper(ILatLong latLong, Mappoint leftUpper) {
    Mappoint mappoint = latLonToPixel(latLong);
    return mappoint.offset(-leftUpper.x, -leftUpper.y);
  }

  /**
   * Returns the top-left point of this tile in absolute pixel coordinates.
   *
   * @return the top-left point
   */
  Mappoint getLeftUpper(Tile tile) {
    return tile.getLeftUpper();
  }

  /// Returns the center point of the given [tile] in absolute pixel coordinates
  Mappoint getCenter(Tile tile) {
    return tile.getCenter();
  }

  MapRectangle boundaryAbsolute(Tile tile) {
    return tile.getMapBoundary();
  }

  /// returns the meters per pixel at the current zoomlevel. Returns 0 at +/-90°
  double meterPerPixel(ILatLong latLong) {
    if (latLong.latitude == 90 || latLong.latitude == -90) return 0;
    int pixels = _mapSizeWithScaleFactor();
    const double pi180 = pi / 180;
    return Projection.EARTH_CIRCUMFERENCE / pixels * cos(latLong.latitude * pi180);
  }

  ///
  /// the size of the whole map in mappixel. At scalefactor 1 (or zoomLevel 0)
  /// the _mapSize is equal to the tileSize.
  ///
  int get mapsize => _mapSize;

  MapRectangle boundingBoxToRectangle(BoundingBox boundingBox) {
    return MapRectangle(longitudeToPixelX(boundingBox.minLongitude), latitudeToPixelY(boundingBox.minLatitude), longitudeToPixelX(boundingBox.maxLongitude),
        latitudeToPixelY(boundingBox.maxLatitude));
  }

  @override
  String toString() {
    return 'PixelProjection{_mapSize: $_mapSize, zoomLevel: ${scalefactor.zoomlevel}}';
  }

  /// Find the maximum zoomLevel where the [boundary] fits in given the current screensize.
  /// This is an expensive operations since we probe each zoomLevel until we find the correct one.
  /// Use it sparingly.
  static int calculateFittingZoomlevel(BoundingBox boundary, Size size) {
    for (int zoomLevel = Scalefactor.MAXZOOMLEVEL; zoomLevel >= 0; --zoomLevel) {
      PixelProjection projection = PixelProjection(zoomLevel);
      Mappoint leftUpper = projection.latLonToPixel(LatLong(boundary.maxLatitude, boundary.minLongitude));
      Mappoint rightBottom = projection.latLonToPixel(LatLong(boundary.minLatitude, boundary.maxLongitude));
      assert(leftUpper.x < rightBottom.x);
      assert(leftUpper.y < rightBottom.y);
      if ((rightBottom.x - leftUpper.x) <= size.width && (rightBottom.y - leftUpper.y) <= size.height) {
        return zoomLevel;
      }
    }
    return 0;
  }
}
