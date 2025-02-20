import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/poiholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';

import '../../../core.dart';
import '../../../datastore.dart';
import '../../../maps.dart';

/// Each subfile consists of:
/// tile index header
//     for each base-tile: tile index entry
//
//     for each base-tile
//         tile header
//         for each POI: POI data
//         for each way: way properties
//             for each wayblock: way data

class SubfileCreator {
  /// Base zoom level of the sub-file, which equals to one block.
  final int baseZoomLevel;

  /// Maximum zoom level for which the block entries tables are made.
  final int zoomLevelMax;

  /// Minimum zoom level for which the block entries tables are made.
  final int zoomLevelMin;

  final bool debugFile;

  final BoundingBox boundingBox;

  /// Size of the sub-file in bytes. Consists of
  /// - tile index header (16 byte if debug is on)
  /// - tile index entries (5 byte per tile of baseZoomLevel)
  /// - for each tile:
  ///   - tile header
  ///   - poi data
  ///   - way data
  // int getSubFileSize() {
  //   int result = 0;
  //   tiledata.forEach((tile, zoominfo) {
  //     if (debugFile) result += 16;
  //     result += 5 * (zoomLevelMax - zoomLevelMin + 1);
  //     result += zoominfo.tileheader!.length;
  //     // result += zoominfo.poiinfo.writebuffer.length;
  //     // result += zoominfo.wayinfo.writebuffer.length;
  //   });
  //   return result;
  // }

  final Map<Tile, Zoominfo> tiledata = {};

  SubfileCreator(
      {required this.baseZoomLevel,
      required this.zoomLevelMax,
      required this.zoomLevelMin,
      required this.debugFile,
      required this.boundingBox}) {
    MercatorProjection projection =
        MercatorProjection.fromZoomlevel(baseZoomLevel);
    for (int tileX = projection.longitudeToTileX(boundingBox.minLongitude);
        tileX <= projection.longitudeToTileX(boundingBox.maxLongitude);
        ++tileX) {
      for (int tileY = projection.latitudeToTileY(boundingBox.maxLatitude);
          tileY <= projection.latitudeToTileY(boundingBox.minLatitude);
          ++tileY) {
        Tile tile = new Tile(tileX, tileY, baseZoomLevel, 0);
        double tileLatitude = projection.tileYToLatitude(tile.tileY);
        double tileLongitude = projection.tileXToLongitude(tile.tileX);
        tiledata[tile] = Zoominfo(
            debugFile, zoomLevelMin, zoomLevelMax, tileLatitude, tileLongitude);
      }
    }
  }

  void addPoidata(
      int zoomlevel, List<PointOfInterest> pois, List<Tagholder> tagholders) {
    for (PointOfInterest pointOfInterest in pois) {
      tiledata.forEach((tile, zoominfo) {
        if (tile.getBoundingBox().containsLatLong(pointOfInterest.position)) {
          zoominfo.addPoidata(zoomlevel, pointOfInterest, tagholders);
        }
      });
    }
  }

  void addWaydata(int zoomlevel, List<Way> ways, List<Tagholder> tagholders) {
    for (Way way in ways) {
      tiledata.forEach((tile, zoominfo) {
        if (tile.getBoundingBox().intersects(way.getBoundingBox())) {
          zoominfo.addWaydata(zoomlevel, way, tagholders);
        }
      });
    }
  }

  void _writeIndexHeaderSignature(Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("+++IndexStart+++");
    }
  }

  Writebuffer writeTileIndex() {
    Writebuffer writebuffer = Writebuffer();
    _writeIndexHeaderSignature(writebuffer);
    // todo find out how to do this
    bool coveredByWater = false;
    int offset = writebuffer.length + 5 * tiledata.length;

    MercatorProjection projection =
        MercatorProjection.fromZoomlevel(baseZoomLevel);
    for (int tileX = projection.longitudeToTileX(boundingBox.minLongitude);
        tileX <= projection.longitudeToTileX(boundingBox.maxLongitude);
        ++tileX) {
      for (int tileY = projection.latitudeToTileY(boundingBox.maxLatitude);
          tileY <= projection.latitudeToTileY(boundingBox.minLatitude);
          ++tileY) {
        _writeTileIndexEntry(writebuffer, coveredByWater, offset);
        // now calculate this tilesize and add it to the offset for the next tile
        Tile tile = new Tile(tileX, tileY, baseZoomLevel, 0);
        Zoominfo zoominfo = tiledata[tile]!;
        zoominfo.writeTile(tile);
        offset += zoominfo.writebuffer!.length;
      }
    }
    return writebuffer;
  }

  /// Note: to calculate how many tile index entries there will be, use the formulae at [http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames] to find out how many tiles will be covered by the bounding box at the base zoom level of the sub file
  void _writeTileIndexEntry(
      Writebuffer writebuffer, bool coveredByWater, int offset) {
    int indexEntry = 0;
    if (coveredByWater) indexEntry = indexEntry |= MapFile.BITMASK_INDEX_WATER;

    // 2.-40. bit (mask: 0x7f ff ff ff ff): 39 bit offset of the tile in the sub file as 5-bytes LONG (optional debug information and index size is also counted; byte order is BigEndian i.e. most significant byte first)
    // If the tile is empty offset(tile,,i,,) = offset(tile,,i+1,,)
    indexEntry = indexEntry |= offset;
    writebuffer.appendInt5(indexEntry);
  }

  Writebuffer writeTiles() {
    final Writebuffer writebuffer = Writebuffer();
    MercatorProjection projection =
        MercatorProjection.fromZoomlevel(baseZoomLevel);
    for (int tileX = projection.longitudeToTileX(boundingBox.minLongitude);
        tileX <= projection.longitudeToTileX(boundingBox.maxLongitude);
        ++tileX) {
      for (int tileY = projection.latitudeToTileY(boundingBox.maxLatitude);
          tileY <= projection.latitudeToTileY(boundingBox.minLatitude);
          ++tileY) {
        Tile tile = new Tile(tileX, tileY, baseZoomLevel, 0);
        Zoominfo zoominfo = tiledata[tile]!;
        writebuffer.appendWritebuffer(zoominfo.writeTile(tile));
      }
    }
    return writebuffer;
  }
}

//////////////////////////////////////////////////////////////////////////////

class Zoominfo {
  final bool debugFile;

  Map<int, Poiinfo> poiinfos = {};

  Map<int, Wayinfo> wayinfos = {};

  double tileLatitude;
  double tileLongitude;

  final int zoomLevelMin;

  final int zoomLevelMax;

  Writebuffer? writebuffer;

  Zoominfo(this.debugFile, this.zoomLevelMin, this.zoomLevelMax,
      this.tileLatitude, this.tileLongitude) {
    for (int zoomlevel = zoomLevelMin; zoomlevel <= zoomLevelMax; ++zoomlevel) {
      poiinfos[zoomlevel] = Poiinfo(debugFile);
      wayinfos[zoomlevel] = Wayinfo(debugFile);
    }
  }

  void addPoidata(
      int zoomlevel, PointOfInterest poi, List<Tagholder> tagholders) {
    for (int zl = zoomLevelMin; zl < zoomlevel; ++zl) {
      // if it is already defined for lower zoomlevel, ignore it
      if (poiinfos[zl]!.contains(poi)) return;
    }
    Poiinfo poiinfo = poiinfos[zoomlevel]!;
    poiinfo.setPoidata(poi, tagholders);
  }

  void addWaydata(int zoomlevel, Way way, List<Tagholder> tagholders) {
    for (int zl = zoomLevelMin; zl < zoomlevel; ++zl) {
      // if it is already defined for lower zoomlevel, ignore it
      if (wayinfos[zl]!.contains(way)) {
        return;
      }
    }
    // if (way.getTag("name") == "place du casino")
    //   print("Adding $way to $zoomlevel at $tileLatitude/$tileLongitude");
    Wayinfo wayinfo = wayinfos[zoomlevel]!;
    wayinfo.setWaydata(way, tagholders);
  }

  Writebuffer writeTile(Tile tile) {
    if (writebuffer != null) return writebuffer!;
    writebuffer = Writebuffer();
    _writeTileHeaderSignature(tile, writebuffer!);

    _writeZoomtable(tile, writebuffer!);

    // the offset to the first way in the block
    int firstWayOffset = 0;
    for (int zoomlevel = zoomLevelMin; zoomlevel <= zoomLevelMax; ++zoomlevel) {
      Poiinfo poiinfo = poiinfos[zoomlevel]!;
      poiinfo.writePoidata(tileLatitude, tileLongitude);
      firstWayOffset += poiinfo.writebuffer!.length;
    }
    writebuffer!.appendUnsignedInt(firstWayOffset);
    for (int zoomlevel = zoomLevelMin; zoomlevel <= zoomLevelMax; ++zoomlevel) {
      Poiinfo poiinfo = poiinfos[zoomlevel]!;
      writebuffer!.appendWritebuffer(poiinfo.writebuffer!);
    }
    for (int zoomlevel = zoomLevelMin; zoomlevel <= zoomLevelMax; ++zoomlevel) {
      Wayinfo wayinfo = wayinfos[zoomlevel]!;
      wayinfo.writeWaydata(tileLatitude, tileLongitude);
      writebuffer!.appendWritebuffer(wayinfo.writebuffer!);
    }
    return writebuffer!;
  }

  /// Processes the block signature, if present.
  ///
  /// @return true if the block signature could be processed successfully, false otherwise.
  void _writeTileHeaderSignature(Tile tile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength(
          "###TileStart${tile.tileX},${tile.tileY}###"
              .padRight(MapFile.SIGNATURE_LENGTH_BLOCK, " "));
    }
  }

  void _writeZoomtable(Tile tile, Writebuffer writebuffer) {
    for (int queryZoomLevel = zoomLevelMin;
        queryZoomLevel <= zoomLevelMax;
        queryZoomLevel++) {
      Poiinfo poiinfo = poiinfos[queryZoomLevel]!;
      Wayinfo wayinfo = wayinfos[queryZoomLevel]!;
      int poiCount = poiinfo.count;
      int wayCount = wayinfo.wayholders.length;
      writebuffer.appendUnsignedInt(poiCount);
      writebuffer.appendUnsignedInt(wayCount);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class Poiinfo {
  final bool debugFile;

  List<Poiholder> poiholders = [];

  Writebuffer? writebuffer;

  int count = 0;

  Poiinfo(this.debugFile);

  void setPoidata(PointOfInterest poi, List<Tagholder> tagholders) {
    Poiholder poiholder = Poiholder(debugFile, poi, tagholders);
    poiholders.add(poiholder);
    ++count;
  }

  bool contains(PointOfInterest poi) {
    return poiholders.firstWhereOrNull((test) => test.poi == poi) != null;
  }

  Writebuffer writePoidata(double tileLatitude, double tileLongitude) {
    if (writebuffer != null) return writebuffer!;
    writebuffer = Writebuffer();
    for (Poiholder poiholder in poiholders) {
      writebuffer!.appendWritebuffer(
          poiholder.writePoidata(tileLatitude, tileLongitude));
    }
    poiholders.clear();
    return writebuffer!;
  }
}

//////////////////////////////////////////////////////////////////////////////

class Wayinfo {
  final bool debugFile;

  List<Wayholder> wayholders = [];

  Writebuffer? writebuffer;

  int count = 0;

  Wayinfo(this.debugFile);

  void setWaydata(Way way, List<Tagholder> tagholders) {
    Wayholder wayholder = Wayholder(debugFile, way, tagholders);
    wayholders.add(wayholder);
    ++count;
  }

  bool contains(Way way) {
    return wayholders.firstWhereOrNull((test) => test.way == way) != null;
  }

  Writebuffer writeWaydata(double tileLatitude, double tileLongitude) {
    if (writebuffer != null) return writebuffer!;
    writebuffer = Writebuffer();
    for (Wayholder wayholder in wayholders) {
      writebuffer!.appendWritebuffer(
          wayholder.writeWaydata(tileLatitude, tileLongitude));
    }
    wayholders.clear();
    return writebuffer!;
  }
}
