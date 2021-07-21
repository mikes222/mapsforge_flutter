import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/projection/projection.dart';
import 'package:mapsforge_flutter/src/projection/scalefactor.dart';

class MercatorProjection implements Projection {
  static final _log = new Logger('MercatorProjection');

  ///
  /// The scalefactor. The scaleFactor is dependent on the zoomLevel (scaleFactor similar to pow(2, zoomLevel) ). The whole world fits into on tile in zoomLevel 0 (=scaleFactor 1).
  final Scalefactor _scalefactor;

  late final int _maxTileCount;

  MercatorProjection.fromZoomlevel(int zoomLevel)
      : _scalefactor = Scalefactor.fromZoomlevel(zoomLevel) {
    //_mapSize = _mapSizeWithScaleFactor(_scaleFactor.scalefactor);
    _maxTileCount = _scalefactor.scalefactor.floor();
  }

  MercatorProjection.fromScalefactor(double scaleFactor)
      : _scalefactor = Scalefactor.fromScalefactor(scaleFactor) {
    //_mapSize = _mapSizeWithScaleFactor(_scaleFactor);
    _maxTileCount =
        Scalefactor.zoomlevelToScalefactor(_scalefactor.zoomlevel).floor();
  }

  Scalefactor get scalefactor => _scalefactor;

  /// @param scaleFactor the scale factor for which the size of the world map should be returned.
  /// @return the horizontal and vertical size of the map in pixel at the given scale.
  /// @throws IllegalArgumentException if the given scale factor is < 1
  // double _mapSizeWithScaleFactor(double scaleFactor) {
  //   assert(scaleFactor >= 1);
  //   return (tileSize.toDouble() * (pow(2, Projection.scaleFactorToZoomLevel(scaleFactor))));
  // }

  /// Converts a longitude coordinate (in degrees) to the tile X number at a certain zoom level.
  ///
  /// @param longitude the longitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile X number of the longitude value.
  @override
  int longitudeToTileX(double longitude) {
    if (longitude == 180) {
      return (_scalefactor.scalefactor - 1).floor();
    }
    int result = ((longitude + 180) / 360 * _scalefactor.scalefactor).floor();
    return result;
  }

  /// Converts a tile X number at a certain zoom level to a longitude coordinate (left side of the tile).
  ///
  /// @param tileX     the tile X number that should be converted.
  /// @param zoomLevel the zoom level at which the number should be converted.
  /// @return the longitude value of the tile X number.
  ///
  @override
  double tileXToLongitude(int tileX) {
    assert(tileX >= 0);
    assert(tileX <= _scalefactor.scalefactor);
    double result = (tileX / _scalefactor.scalefactor * 360 - 180);
    return result;
    //return pixelXToLongitude(tileX * tileSize.toDouble());
  }

  /// Converts a tile Y number at a certain zoom level to a latitude coordinate.
  ///
  /// @param tileY     the tile Y number that should be converted.
  /// @param zoomLevel the zoom level at which the number should be converted.
  /// @return the latitude value of the tile Y number.
  @override
  double tileYToLatitude(int tileY) {
    assert(tileY >= 0);
    assert(tileY <= scalefactor.scalefactor);
    const double pi2 = 2 * pi;
    const double pi360 = 360 / pi;
    double y = 0.5 - (tileY / _scalefactor.scalefactor);
    return 90 - pi360 * atan(exp(-y * pi2));
  }

  /// Converts a latitude coordinate (in degrees) to a tile Y number at a certain zoom level.
  ///
  /// @param latitude  the latitude coordinate that should be converted.
  /// @param zoomLevel the zoom level at which the coordinate should be converted.
  /// @return the tile Y number of the latitude value.
  @override
  int latitudeToTileY(double latitude) {
    const double pi180 = pi / 180;
    const double pi4 = 4 * pi;
    double sinLatitude = sin(latitude * pi180);
    // exceptions for 90 and -90 degrees
    if (sinLatitude == 1.0) return 0;
    if (sinLatitude == -1.0) return _scalefactor.scalefactor.floor() - 1;
    double tileY = (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / pi4);
    // print(
    //     "tileY: $tileY, sinLat: $sinLatitude, log: ${log((1 + sinLatitude) / (1 - sinLatitude))}");
    int result = (tileY * _scalefactor.scalefactor).floor();
    //print("Mercator: ${tileY * _scalefactor.scalefactor}");
    // seems with Latitude boundingBox.maxLatitude we get -1.5543122344752192e-15 so correct it to 0
    if (result < 0) return 0;
    if (result >= _maxTileCount) return _maxTileCount - 1;
    return result;
  }

  ///
  /// The bounding box of this tile in lat/lon coordinates
  @override
  BoundingBox boundingBoxOfTile(Tile tile) {
    double minLatitude =
        max(Projection.LATITUDE_MIN, tileYToLatitude(tile.tileY + 1));
    double minLongitude =
        max(Projection.LONGITUDE_MIN, tileXToLongitude(tile.tileX));
    double maxLatitude =
        min(Projection.LATITUDE_MAX, tileYToLatitude(tile.tileY));
    double maxLongitude =
        min(Projection.LONGITUDE_MAX, tileXToLongitude(tile.tileX + 1));
    if (maxLongitude == -180) {
      // fix for dateline crossing, where the right tile starts at -180 and causes an invalid bbox
      maxLongitude = 180;
    }
    return BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }

  @override
  BoundingBox boundingBoxOfTiles(Tile upperLeft, Tile lowerRight) {
    assert(upperLeft.zoomLevel == lowerRight.zoomLevel);
    assert(upperLeft.tileY <= lowerRight.tileY);
    assert(upperLeft.tileX <= lowerRight.tileX);
    double minLatitude =
        max(Projection.LATITUDE_MIN, tileYToLatitude(lowerRight.tileY + 1));
    double minLongitude =
        max(Projection.LONGITUDE_MIN, tileXToLongitude(upperLeft.tileX));
    double maxLatitude =
        min(Projection.LATITUDE_MAX, tileYToLatitude(upperLeft.tileY));
    double maxLongitude =
        min(Projection.LONGITUDE_MAX, tileXToLongitude(lowerRight.tileX + 1));
    if (maxLongitude == -180) {
      // fix for dateline crossing, where the right tile starts at -180 and causes an invalid bbox
      maxLongitude = 180;
    }
    return BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }
//double get mapSize => _mapSize;

}
