import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/src/utils/mapsforge_settings_mgr.dart';

/// Pixel-based projection extending Mercator projection with screen coordinate support.
///
/// This class extends MercatorProjection to provide conversions between geographic
/// coordinates and pixel coordinates on screen. It handles:
/// - Geographic coordinates ↔ pixel coordinates
/// - Pixel coordinates ↔ tile coordinates
/// - Relative positioning within tiles
/// - Distance and scale calculations
///
/// Key features:
/// - Configurable tile size for different display densities
/// - Cached calculations for performance
/// - Relative coordinate calculations for tile rendering
/// - Meter-per-pixel calculations for scale awareness
class PixelProjection extends MercatorProjection {
  /// The size of a tile in pixels. Each tile has the same width and height.
  /// This value is typically 256 or 512 pixels depending on display density.
  final double tileSize;

  /// The total size of the world map in pixels at the current zoom level.
  ///
  /// At zoom level 0 (scalefactor 1), mapSize equals tileSize.
  /// At zoom level n, mapSize = tileSize × 2^n.
  late int _mapSize;

  static final Map<String, double> _pixelDiffCache = {};

  PixelProjection(super.zoomlevel) : tileSize = MapsforgeSettingsMgr().tileSize, super.fromZoomlevel() {
    _mapSize = _mapSizeWithScaleFactor();
  }

  /// Calculates the total map size in pixels for the current scale factor.
  ///
  /// Returns the width/height of the entire world map in pixels
  int _mapSizeWithScaleFactor() {
    return (tileSize * scalefactor.scalefactor).round();
  }

  /// Converts a pixel X coordinate to the corresponding tile X number.
  ///
  /// [pixelX] The pixel X coordinate to convert
  /// Returns the tile X coordinate containing this pixel
  int pixelXToTileX(double pixelX) {
    assert(pixelX >= 0);
    assert(pixelX <= _mapSize);
    return max(min(pixelX / tileSize, scalefactor.scalefactor - 1), 0).floor();
  }

  /// Converts a pixel Y coordinate to the corresponding tile Y number.
  ///
  /// [pixelY] The pixel Y coordinate to convert
  /// Returns the tile Y coordinate containing this pixel
  int pixelYToTileY(double pixelY) {
    assert(pixelY >= 0, "pixelY ($pixelY) should be >= 0");
    assert(pixelY <= _mapSize, "pixelY ($pixelY) should be <= mapSize ($_mapSize)");
    return max(min(pixelY / tileSize, scalefactor.scalefactor - 1), 0).floor();
  }

  /// Converts a latitude coordinate to the corresponding pixel Y coordinate.
  ///
  /// Uses Mercator projection formulas to calculate the pixel position.
  ///
  /// [latitude] The latitude coordinate in degrees
  /// Returns the pixel Y coordinate (0 to mapSize whereas 0 is +90° and mapSize is -90°)
  double latitudeToPixelY(double latitude) {
    const double pi180 = pi / 180;
    const double pi4 = 4 * pi;
    double sinLatitude = sin(latitude * pi180);
    // FIXME improve this formula so that it works correctly without the clipping
    double pixelY = (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / pi4) * _mapSize;
    return min(max(0, pixelY), _mapSize.toDouble());
  }

  /// Converts a pixel Y coordinate to the corresponding latitude coordinate.
  ///
  /// Uses inverse Mercator projection to calculate the geographic coordinate.
  ///
  /// [pixelY] The pixel Y coordinate to convert
  /// Returns the latitude in degrees
  double pixelYToLatitude(double pixelY) {
    pixelY = min(max(0, pixelY), _mapSize.toDouble());
    assert(pixelY >= 0, "pixelY ($pixelY) should be >= 0");
    assert(pixelY <= _mapSize, "pixelY ($pixelY) should be <= mapSize ($_mapSize)");
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
    if (pixelDiff <= 10) {
      // fast algorithm for small pixel differences
      const double pi180 = pi / 180;
      return (pixelDiff * (360 / _mapSize) * cos(latitude * pi180)).abs();
    }
    String key = "${_mapSize}_${latitude.round()}_$pixelDiff";
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
  MappointRelative pixelRelativeToTile(ILatLong latLong, Tile tile) {
    Mappoint mappoint = latLonToPixel(latLong);
    Mappoint tilePoint = getLeftUpper(tile);
    return mappoint.offset(tilePoint);
  }

  /// Calculates the absolute pixel position for a tile and tile size relative to origin
  ///
  /// @param latLong the geographic position.
  /// @param tile    tile
  /// @return the relative pixel position to the origin values (e.g. for a tile)
  MappointRelative pixelRelativeToLeftUpper(ILatLong latLong, Mappoint leftUpper) {
    Mappoint mappoint = latLonToPixel(latLong);
    return mappoint.offset(leftUpper);
  }

  /// Returns the top-left point of this tile in absolute pixel coordinates.
  ///
  /// @return the top-left point
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
    return MapRectangle(
      longitudeToPixelX(boundingBox.minLongitude),
      latitudeToPixelY(boundingBox.minLatitude),
      longitudeToPixelX(boundingBox.maxLongitude),
      latitudeToPixelY(boundingBox.maxLatitude),
    );
  }

  @override
  String toString() {
    return 'PixelProjection{_mapSize: $_mapSize, zoomLevel: ${scalefactor.zoomlevel}}';
  }

  /// Find the maximum zoomLevel where the [boundary] fits in given the current screensize.
  /// This is an expensive operations since we probe each zoomLevel until we find the correct one.
  /// Use it sparingly.
  static int calculateFittingZoomlevel(BoundingBox boundary, MapSize size) {
    for (int zoomLevel = MapsforgeSettingsMgr.defaultMaxZoomlevel; zoomLevel >= 0; --zoomLevel) {
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
