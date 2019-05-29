import 'dart:math';

import '../model/latlong.dart';
import '../model/mappoint.dart';
import '../model/tile.dart';

/**
 * An implementation of the spherical Mercator projection.
 * <p/>
 * There are generally two methods for each operation: one taking a byte zoomlevel and
 * a parallel one taking a double scaleFactor. The scaleFactor is Math.pow(2, zoomLevel)
 * for a given zoomlevel, but it the operations take intermediate values as well.
 * The zoomLevel operation is a little faster as it can make use of shift operations,
 * the scaleFactor operation offers greater flexibility in computing the values for
 * intermediate zoomlevels.
 */
class MercatorProjection {
  /**
   * The circumference of the earth at the equator in meters.
   */
  static final double EARTH_CIRCUMFERENCE = 40075016.686;

  /**
   * Maximum possible latitude coordinate of the map.
   */
  static final double LATITUDE_MAX = 85.05112877980659;

  /**
   * Minimum possible latitude coordinate of the map.
   */
  static final double LATITUDE_MIN = -LATITUDE_MAX;

// TODO some operations actually do not rely on the tile size, but are composited
// from operations that require a tileSize parameter (which is effectively cancelled
// out). A shortcut version of those operations should be implemented and then this
// variable be removed.
  static final int DUMMY_TILE_SIZE = 256;

  /**
   * Calculates the distance on the ground that is represented by a single pixel on the map.
   *
   * @param latitude    the latitude coordinate at which the resolution should be calculated.
   * @param scaleFactor the scale at which the resolution should be calculated.
   * @return the ground resolution at the given latitude and scale.
   */
  static double calculateGroundResolutionWithScaleFactor(
      double latitude, double scaleFactor, int tileSize) {
    int mapSize = getMapSizeWithScaleFactor(scaleFactor, tileSize);
    return cos(latitude * (pi / 180)) * EARTH_CIRCUMFERENCE / mapSize;
  }

  /**
   * Calculates the distance on the ground that is represented by a single pixel on the map.
   *
   * @param latitude the latitude coordinate at which the resolution should be calculated.
   * @param mapSize  precomputed size of map.
   * @return the ground resolution at the given latitude and map size.
   */
  static double calculateGroundResolution(double latitude, int mapSize) {
    return cos(latitude * (pi / 180)) * EARTH_CIRCUMFERENCE / mapSize;
  }

  /**
   * Get LatLong from Pixels.
   */
  static LatLong fromPixelsWithScaleFactor(
      double pixelX, double pixelY, double scaleFactor, int tileSize) {
    return new LatLong(
        pixelYToLatitudeWithScaleFactor(pixelY, scaleFactor, tileSize),
        pixelXToLongitudeWithScaleFactor(pixelX, scaleFactor, tileSize));
  }

  /**
   * Get LatLong from Pixels.
   */
  static LatLong fromPixels(double pixelX, double pixelY, int mapSize) {
    return new LatLong(
        pixelYToLatitude(pixelY, mapSize), pixelXToLongitude(pixelX, mapSize));
  }

  /**
   * @param scaleFactor the scale factor for which the size of the world map should be returned.
   * @return the horizontal and vertical size of the map in pixel at the given scale.
   * @throws IllegalArgumentException if the given scale factor is < 1
   */
  static int getMapSizeWithScaleFactor(double scaleFactor, int tileSize) {
    if (scaleFactor < 1) {
      throw new Exception("scale factor must not < 1 $scaleFactor");
    }
    return (tileSize * (pow(2, scaleFactorToZoomLevel(scaleFactor))));
  }

  /**
   * @param zoomLevel the zoom level for which the size of the world map should be returned.
   * @return the horizontal and vertical size of the map in pixel at the given zoom level.
   * @throws IllegalArgumentException if the given zoom level is negative.
   */
  static int getMapSize(int zoomLevel, int tileSize) {
    if (zoomLevel < 0) {
      throw new Exception("zoom level must not be negative: $zoomLevel");
    }
    return tileSize << zoomLevel;
  }

  static Point getPixelWithScaleFactor(
      LatLong latLong, double scaleFactor, int tileSize) {
    double pixelX = MercatorProjection.longitudeToPixelXWithScaleFactor(
        latLong.longitude, scaleFactor, tileSize);
    double pixelY = MercatorProjection.latitudeToPixelYWithScaleFactor(
        latLong.latitude, scaleFactor, tileSize);
    return new Point(pixelX, pixelY);
  }

  static Point getPixel(LatLong latLong, int mapSize) {
    double pixelX = MercatorProjection.longitudeToPixelXAtMapSize(
        latLong.longitude, mapSize);
    double pixelY = MercatorProjection.latitudeToPixelYWithMapSize(
        latLong.latitude, mapSize);
    return new Point(pixelX, pixelY);
  }

  /**
   * Calculates the absolute pixel position for a map size and tile size
   *
   * @param latLong the geographic position.
   * @param mapSize precomputed size of map.
   * @return the absolute pixel coordinates (for world)
   */

  static Mappoint getPixelAbsolute(LatLong latLong, int mapSize) {
    return getPixelRelative(latLong, mapSize, 0, 0);
  }

  /**
   * Calculates the absolute pixel position for a map size and tile size relative to origin
   *
   * @param latLong the geographic position.
   * @param mapSize precomputed size of map.
   * @return the relative pixel position to the origin values (e.g. for a tile)
   */
  static Mappoint getPixelRelative(
      LatLong latLong, int mapSize, double x, double y) {
    double pixelX = MercatorProjection.longitudeToPixelXAtMapSize(
            latLong.longitude, mapSize) -
        x;
    double pixelY = MercatorProjection.latitudeToPixelYWithMapSize(
            latLong.latitude, mapSize) -
        y;
    return new Mappoint(pixelX, pixelY);
  }

  /**
   * Calculates the absolute pixel position for a map size and tile size relative to origin
   *
   * @param latLong the geographic position.
   * @param mapSize precomputed size of map.
   * @return the relative pixel position to the origin values (e.g. for a tile)
   */
  static Mappoint getPixelRelativeOrigin(
      LatLong latLong, int mapSize, Mappoint origin) {
    return getPixelRelative(latLong, mapSize, origin.x, origin.y);
  }

  /**
   * Calculates the absolute pixel position for a tile and tile size relative to origin
   *
   * @param latLong the geographic position.
   * @param tile    tile
   * @return the relative pixel position to the origin values (e.g. for a tile)
   */
  static Mappoint getPixelRelativeToTile(LatLong latLong, Tile tile) {
    return getPixelRelativeOrigin(latLong, tile.mapSize, tile.getOrigin());
  }

  /**
   * Converts a latitude coordinate (in degrees) to a pixel Y coordinate at a certain scale.
   *
   * @param latitude    the latitude coordinate that should be converted.
   * @param scaleFactor the scale factor at which the coordinate should be converted.
   * @return the pixel Y coordinate of the latitude value.
   */
  static double latitudeToPixelYWithScaleFactor(
      double latitude, double scaleFactor, int tileSize) {
    double sinLatitude = sin(latitude * (pi / 180));
    int mapSize = getMapSizeWithScaleFactor(scaleFactor, tileSize);
// FIXME improve this formula so that it works correctly without the clipping
    double pixelY =
        (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * pi)) * mapSize;
    return min(max(0, pixelY), mapSize.toDouble());
  }

  /**
   * Converts a latitude coordinate (in degrees) to a pixel Y coordinate at a certain zoom level.
   *
   * @param latitude  the latitude coordinate that should be converted.
   * @param zoomLevel the zoom level at which the coordinate should be converted.
   * @return the pixel Y coordinate of the latitude value.
   */
  static double latitudeToPixelY(double latitude, int zoomLevel, int tileSize) {
    double sinLatitude = sin(latitude * (pi / 180));
    int mapSize = getMapSize(zoomLevel, tileSize);
// FIXME improve this formula so that it works correctly without the clipping
    double pixelY =
        (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * pi)) * mapSize;
    return min(max(0, pixelY), mapSize.toDouble());
  }

  /**
   * Converts a latitude coordinate (in degrees) to a pixel Y coordinate at a certain map size.
   *
   * @param latitude the latitude coordinate that should be converted.
   * @param mapSize  precomputed size of map.
   * @return the pixel Y coordinate of the latitude value.
   */
  static double latitudeToPixelYWithMapSize(double latitude, int mapSize) {
    double sinLatitude = sin(latitude * (pi / 180));
// FIXME improve this formula so that it works correctly without the clipping
    double pixelY =
        (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * pi)) * mapSize;
    return min(max(0, pixelY), mapSize.toDouble());
  }

  /**
   * Converts a latitude coordinate (in degrees) to a tile Y number at a certain scale.
   *
   * @param latitude    the latitude coordinate that should be converted.
   * @param scaleFactor the scale factor at which the coordinate should be converted.
   * @return the tile Y number of the latitude value.
   */
  static int latitudeToTileYWithScaleFactor(
      double latitude, double scaleFactor) {
    return pixelYToTileYWithScaleFactor(
        latitudeToPixelYWithScaleFactor(latitude, scaleFactor, DUMMY_TILE_SIZE),
        scaleFactor,
        DUMMY_TILE_SIZE);
  }

  /**
   * Converts a latitude coordinate (in degrees) to a tile Y number at a certain zoom level.
   *
   * @param latitude  the latitude coordinate that should be converted.
   * @param zoomLevel the zoom level at which the coordinate should be converted.
   * @return the tile Y number of the latitude value.
   */
  static int latitudeToTileY(double latitude, int zoomLevel) {
    return pixelYToTileY(latitudeToPixelY(latitude, zoomLevel, DUMMY_TILE_SIZE),
        zoomLevel, DUMMY_TILE_SIZE);
  }

  /**
   * Converts a longitude coordinate (in degrees) to a pixel X coordinate at a certain scale factor.
   *
   * @param longitude   the longitude coordinate that should be converted.
   * @param scaleFactor the scale factor at which the coordinate should be converted.
   * @return the pixel X coordinate of the longitude value.
   */
  static double longitudeToPixelXWithScaleFactor(
      double longitude, double scaleFactor, int tileSize) {
    int mapSize = getMapSizeWithScaleFactor(scaleFactor, tileSize);
    return (longitude + 180) / 360 * mapSize;
  }

  /**
   * Converts a longitude coordinate (in degrees) to a pixel X coordinate at a certain zoom level.
   *
   * @param longitude the longitude coordinate that should be converted.
   * @param zoomLevel the zoom level at which the coordinate should be converted.
   * @param tileSize  the tile size
   * @return the pixel X coordinate of the longitude value.
   */
  static double longitudeToPixelX(
      double longitude, int zoomLevel, int tileSize) {
    int mapSize = getMapSize(zoomLevel, tileSize);
    return (longitude + 180) / 360 * mapSize;
  }

  /**
   * Converts a longitude coordinate (in degrees) to a pixel X coordinate at a certain map size.
   *
   * @param longitude the longitude coordinate that should be converted.
   * @param mapSize   precomputed size of map.
   * @return the pixel X coordinate of the longitude value.
   */
  static double longitudeToPixelXAtMapSize(double longitude, int mapSize) {
    return (longitude + 180) / 360 * mapSize;
  }

  /**
   * Converts a longitude coordinate (in degrees) to the tile X number at a certain scale factor.
   *
   * @param longitude   the longitude coordinate that should be converted.
   * @param scaleFactor the scale factor at which the coordinate should be converted.
   * @return the tile X number of the longitude value.
   */
  static int longitudeToTileXWithScaleFactor(
      double longitude, double scaleFactor) {
    return pixelXToTileXWithScaleFactor(
        longitudeToPixelXWithScaleFactor(
            longitude, scaleFactor, DUMMY_TILE_SIZE),
        scaleFactor,
        DUMMY_TILE_SIZE);
  }

  /**
   * Converts a longitude coordinate (in degrees) to the tile X number at a certain zoom level.
   *
   * @param longitude the longitude coordinate that should be converted.
   * @param zoomLevel the zoom level at which the coordinate should be converted.
   * @return the tile X number of the longitude value.
   */
  static int longitudeToTileX(double longitude, int zoomLevel) {
    return pixelXToTileX(
        longitudeToPixelX(longitude, zoomLevel, DUMMY_TILE_SIZE),
        zoomLevel,
        DUMMY_TILE_SIZE);
  }

  /**
   * Converts meters to pixels at latitude for zoom-level.
   *
   * @param meters      the meters to convert
   * @param latitude    the latitude for the conversion.
   * @param scaleFactor the scale factor for the conversion.
   * @return pixels that represent the meters at the given zoom-level and latitude.
   */
  static double metersToPixelsWithScaleFactor(
      double meters, double latitude, double scaleFactor, int tileSize) {
    return meters /
        MercatorProjection.calculateGroundResolutionWithScaleFactor(
            latitude, scaleFactor, tileSize);
  }

  /**
   * Converts meters to pixels at latitude for zoom-level.
   *
   * @param meters   the meters to convert
   * @param latitude the latitude for the conversion.
   * @param mapSize  precomputed size of map.
   * @return pixels that represent the meters at the given zoom-level and latitude.
   */
  static double metersToPixels(double meters, double latitude, int mapSize) {
    return meters /
        MercatorProjection.calculateGroundResolution(latitude, mapSize);
  }

  /**
   * Converts a pixel X coordinate at a certain scale to a longitude coordinate.
   *
   * @param pixelX      the pixel X coordinate that should be converted.
   * @param scaleFactor the scale factor at which the coordinate should be converted.
   * @return the longitude value of the pixel X coordinate.
   * @throws IllegalArgumentException if the given pixelX coordinate is invalid.
   */
  static double pixelXToLongitudeWithScaleFactor(
      double pixelX, double scaleFactor, int tileSize) {
    int mapSize = getMapSizeWithScaleFactor(scaleFactor, tileSize);
    if (pixelX < 0 || pixelX > mapSize) {
      throw new Exception(
          "invalid pixelX coordinate at scale $scaleFactor: $pixelX");
    }
    return 360 * ((pixelX / mapSize) - 0.5);
  }

  /**
   * Converts a pixel X coordinate at a certain map size to a longitude coordinate.
   *
   * @param pixelX  the pixel X coordinate that should be converted.
   * @param mapSize precomputed size of map.
   * @return the longitude value of the pixel X coordinate.
   * @throws IllegalArgumentException if the given pixelX coordinate is invalid.
   */

  static double pixelXToLongitude(double pixelX, int mapSize) {
    if (pixelX < 0 || pixelX > mapSize) {
      throw new Exception("invalid pixelX coordinate $mapSize: $pixelX");
    }
    return 360 * ((pixelX / mapSize) - 0.5);
  }

  /**
   * Converts a pixel X coordinate to the tile X number.
   *
   * @param pixelX      the pixel X coordinate that should be converted.
   * @param scaleFactor the scale factor at which the coordinate should be converted.
   * @return the tile X number.
   */
  static int pixelXToTileXWithScaleFactor(
      double pixelX, double scaleFactor, int tileSize) {
    return min(max(pixelX / tileSize, 0), scaleFactor - 1).round();
  }

  /**
   * Converts a pixel X coordinate to the tile X number.
   *
   * @param pixelX    the pixel X coordinate that should be converted.
   * @param zoomLevel the zoom level at which the coordinate should be converted.
   * @return the tile X number.
   */
  static int pixelXToTileX(double pixelX, int zoomLevel, int tileSize) {
    return min(max(pixelX / tileSize, 0), pow(2, zoomLevel) - 1).round();
  }

  /**
   * Converts a pixel Y coordinate at a certain scale to a latitude coordinate.
   *
   * @param pixelY      the pixel Y coordinate that should be converted.
   * @param scaleFactor the scale factor at which the coordinate should be converted.
   * @return the latitude value of the pixel Y coordinate.
   * @throws IllegalArgumentException if the given pixelY coordinate is invalid.
   */
  static double pixelYToLatitudeWithScaleFactor(
      double pixelY, double scaleFactor, int tileSize) {
    int mapSize = getMapSizeWithScaleFactor(scaleFactor, tileSize);
    if (pixelY < 0 || pixelY > mapSize) {
      throw new Exception(
          "invalid pixelY coordinate at scale $scaleFactor: $pixelY");
    }
    double y = 0.5 - (pixelY / mapSize);
    return 90 - 360 * atan(exp(-y * (2 * pi))) / pi;
  }

  /**
   * Converts a pixel Y coordinate at a certain map size to a latitude coordinate.
   *
   * @param pixelY  the pixel Y coordinate that should be converted.
   * @param mapSize precomputed size of map.
   * @return the latitude value of the pixel Y coordinate.
   * @throws IllegalArgumentException if the given pixelY coordinate is invalid.
   */
  static double pixelYToLatitude(double pixelY, int mapSize) {
    if (pixelY < 0 || pixelY > mapSize) {
      throw new Exception("invalid pixelY coordinate $mapSize: $pixelY");
    }
    double y = 0.5 - (pixelY / mapSize);
    return 90 - 360 * atan(exp(-y * (2 * pi))) / pi;
  }

  /**
   * Converts a pixel Y coordinate to the tile Y number.
   *
   * @param pixelY      the pixel Y coordinate that should be converted.
   * @param scaleFactor the scale factor at which the coordinate should be converted.
   * @return the tile Y number.
   */
  static int pixelYToTileYWithScaleFactor(
      double pixelY, double scaleFactor, int tileSize) {
    return min(max(pixelY / tileSize, 0), scaleFactor - 1).round();
  }

  /**
   * Converts a pixel Y coordinate to the tile Y number.
   *
   * @param pixelY    the pixel Y coordinate that should be converted.
   * @param zoomLevel the zoom level at which the coordinate should be converted.
   * @return the tile Y number.
   */
  static int pixelYToTileY(double pixelY, int zoomLevel, int tileSize) {
    return min(max(pixelY / tileSize, 0), pow(2, zoomLevel) - 1).round();
  }

  /**
   * Converts a scaleFactor to a zoomLevel.
   * Note that this will return a double, as the scale factors cover the
   * intermediate zoom levels as well.
   *
   * @param scaleFactor the scale factor to convert to a zoom level.
   * @return the zoom level.
   */
  static double scaleFactorToZoomLevel(double scaleFactor) {
    return log(scaleFactor) / log(2);
  }

  /**
   * @param tileNumber the tile number that should be converted.
   * @return the pixel coordinate for the given tile number.
   */
  static int tileToPixel(int tileNumber, int tileSize) {
    return tileNumber * tileSize;
  }

  /**
   * Converts a tile X number at a certain scale to a longitude coordinate.
   *
   * @param tileX       the tile X number that should be converted.
   * @param scaleFactor the scale factor at which the number should be converted.
   * @return the longitude value of the tile X number.
   */
  static double tileXToLongitudeWithScaleFactor(int tileX, double scaleFactor) {
    return pixelXToLongitudeWithScaleFactor(
        tileX * DUMMY_TILE_SIZE.toDouble(), scaleFactor, DUMMY_TILE_SIZE);
  }

  /**
   * Converts a tile X number at a certain zoom level to a longitude coordinate.
   *
   * @param tileX     the tile X number that should be converted.
   * @param zoomLevel the zoom level at which the number should be converted.
   * @return the longitude value of the tile X number.
   */
  static double tileXToLongitude(int tileX, int zoomLevel) {
    return pixelXToLongitude(tileX * DUMMY_TILE_SIZE.toDouble(),
        getMapSize(zoomLevel, DUMMY_TILE_SIZE));
  }

  /**
   * Converts a tile Y number at a certain scale to a latitude coordinate.
   *
   * @param tileY       the tile Y number that should be converted.
   * @param scaleFactor the scale factor at which the number should be converted.
   * @return the latitude value of the tile Y number.
   */
  static double tileYToLatitudeWithScaleFactor(int tileY, double scaleFactor) {
    return pixelYToLatitudeWithScaleFactor(
        tileY * DUMMY_TILE_SIZE.toDouble(), scaleFactor, DUMMY_TILE_SIZE);
  }

  /**
   * Converts a tile Y number at a certain zoom level to a latitude coordinate.
   *
   * @param tileY     the tile Y number that should be converted.
   * @param zoomLevel the zoom level at which the number should be converted.
   * @return the latitude value of the tile Y number.
   */
  static double tileYToLatitude(int tileY, int zoomLevel) {
    return pixelYToLatitude(tileY * DUMMY_TILE_SIZE.toDouble(),
        getMapSize(zoomLevel, DUMMY_TILE_SIZE));
  }

  /**
   * Converts a zoom level to a scale factor.
   *
   * @param zoomLevel the zoom level to convert.
   * @return the corresponding scale factor.
   */
  static double zoomLevelToScaleFactor(int zoomLevel) {
    return pow(2, zoomLevel);
  }
}
