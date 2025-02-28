import 'dart:math' as Math;

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/poiholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';

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

  final ZoomlevelRange zoomlevelRange;

  final BoundingBox boundingBox;

  final List<Zoominfo> basetiledata = [];

  late final int minX;

  late final int minY;

  late final int maxX;

  late final int maxY;

  final MapHeaderInfo mapHeaderInfo;

  SubfileCreator(
      {required this.baseZoomLevel,
      required this.zoomlevelRange,
      required this.boundingBox,
      required this.mapHeaderInfo}) {
    MercatorProjection projection =
        MercatorProjection.fromZoomlevel(baseZoomLevel);
    minX = projection.longitudeToTileX(boundingBox.minLongitude);
    maxX = projection.longitudeToTileX(boundingBox.maxLongitude);
    minY = projection.latitudeToTileY(boundingBox.maxLatitude);
    maxY = projection.latitudeToTileY(boundingBox.minLatitude);
    for (int tileY = minY; tileY <= maxY; ++tileY) {
      for (int tileX = minX; tileX <= maxX; ++tileX) {
        Tile tile = new Tile(tileX, tileY, baseZoomLevel, 0);
        basetiledata.add(
            Zoominfo(zoomlevelRange, tile, mapHeaderInfo.languagesPreference));
      }
    }
  }

  int index(int tileX, int tileY) {
    return (tileY - minY) * (maxX - minX + 1) + (tileX - minX);
  }

  void addPoidata(ZoomlevelRange zoomlevelRange, List<PointOfInterest> pois,
      List<Tagholder> tagholders) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    for (PointOfInterest pointOfInterest in pois) {
      bool found = false;
      for (Zoominfo zoominfo in basetiledata) {
        if (zoominfo.tile
            .getBoundingBox()
            .containsLatLong(pointOfInterest.position)) {
          zoominfo.addPoidata(zoomlevelRange, pointOfInterest, tagholders);
          found = true;
          break;
        }
      }
      //if (!found) print("Not found: $pointOfInterest");
    }
  }

  void addWaydata(ZoomlevelRange zoomlevelRange, List<Way> ways,
      List<Tagholder> tagholders) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    for (Way way in ways) {
      basetiledata.forEach((zoominfo) {
        if (zoominfo.tile.getBoundingBox().intersects(way.getBoundingBox()) ||
            zoominfo.tile
                .getBoundingBox()
                .containsBoundingBox(way.getBoundingBox())) {
          zoominfo.addWaydata(zoomlevelRange, way, tagholders);
        }
      });
    }
  }

  void _writeIndexHeaderSignature(bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("+++IndexStart+++");
    }
  }

  Writebuffer writeTileIndex(bool debugFile) {
    Writebuffer writebuffer = Writebuffer();
    _writeIndexHeaderSignature(debugFile, writebuffer);
    // todo find out how to do this
    bool coveredByWater = false;
    int offset = writebuffer.length + 5 * (maxX - minX + 1) * (maxY - minY + 1);
    int firstOffset = offset;
    for (int tileY = minY; tileY <= maxY; ++tileY) {
      for (int tileX = minX; tileX <= maxX; ++tileX) {
        _writeTileIndexEntry(writebuffer, coveredByWater, offset);
        // now calculate this tilesize and add it to the offset for the next tile
        Zoominfo zoominfo = basetiledata[index(tileX, tileY)];
        zoominfo.writeTile(debugFile);
        offset += zoominfo.writebuffer!.length;
      }
    }
    assert(firstOffset == writebuffer.length,
        "$firstOffset != ${writebuffer.length} with debug=$debugFile and baseZoomLevel=$baseZoomLevel, ${basetiledata.length}, $minX, $minY, $maxX, $maxY");

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

  Writebuffer writeTiles(bool debugFile) {
    final Writebuffer writebuffer = Writebuffer();
    for (int tileY = minY; tileY <= maxY; ++tileY) {
      for (int tileX = minX; tileX <= maxX; ++tileX) {
        Zoominfo zoominfo = basetiledata[index(tileX, tileY)];
        writebuffer.appendWritebuffer(zoominfo.writeTile(debugFile));
      }
    }
    return writebuffer;
  }
}

//////////////////////////////////////////////////////////////////////////////

class Zoominfo {
  Map<int, Poiinfo> poiinfos = {};

  Map<int, Wayinfo> wayinfos = {};

  final Tile tile;

  final ZoomlevelRange zoomlevelRange;

  Writebuffer? writebuffer;

  String? languagesPreference;

  Zoominfo(this.zoomlevelRange, this.tile, this.languagesPreference) {
    for (int zoomlevel = zoomlevelRange.zoomlevelMin;
        zoomlevel <= zoomlevelRange.zoomlevelMax;
        ++zoomlevel) {
      poiinfos[zoomlevel] = Poiinfo(languagesPreference);
      wayinfos[zoomlevel] = Wayinfo(languagesPreference);
    }
  }

  void addPoidata(ZoomlevelRange zoomlevelRange, PointOfInterest poi,
      List<Tagholder> tagholders) {
    poiinfos[Math.max(
            this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!
        .setPoidata(poi, tagholders);
  }

  void addWaydata(
      ZoomlevelRange zoomlevelRange, Way way, List<Tagholder> tagholders) {
    wayinfos[Math.max(
            this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!
        .setWaydata(way, tagholders);
  }

  Writebuffer writeTile(bool debugFile) {
    if (writebuffer != null) return writebuffer!;
    writebuffer = Writebuffer();
    _writeTileHeaderSignature(debugFile, tile, writebuffer!);

    _writeZoomtable(tile, writebuffer!);

    MercatorProjection projection =
        MercatorProjection.fromZoomlevel(tile.zoomLevel);
    double tileLatitude = projection.tileYToLatitude(tile.tileY);
    double tileLongitude = projection.tileXToLongitude(tile.tileX);

    // the offset to the first way in the block
    int firstWayOffset = 0;
    for (int zoomlevel = zoomlevelRange.zoomlevelMin;
        zoomlevel <= zoomlevelRange.zoomlevelMax;
        ++zoomlevel) {
      Poiinfo poiinfo = poiinfos[zoomlevel]!;
      poiinfo.writePoidata(debugFile, tileLatitude, tileLongitude);
      firstWayOffset += poiinfo.writebuffer!.length;
    }
    writebuffer!.appendUnsignedInt(firstWayOffset);
    for (int zoomlevel = zoomlevelRange.zoomlevelMin;
        zoomlevel <= zoomlevelRange.zoomlevelMax;
        ++zoomlevel) {
      Poiinfo poiinfo = poiinfos[zoomlevel]!;
      writebuffer!.appendWritebuffer(poiinfo.writebuffer!);
    }
    for (int zoomlevel = zoomlevelRange.zoomlevelMin;
        zoomlevel <= zoomlevelRange.zoomlevelMax;
        ++zoomlevel) {
      Wayinfo wayinfo = wayinfos[zoomlevel]!;
      wayinfo.writeWaydata(debugFile, tile, tileLatitude, tileLongitude);
      writebuffer!.appendWritebuffer(wayinfo.writebuffer!);
    }
    return writebuffer!;
  }

  /// Processes the block signature, if present.
  ///
  /// @return true if the block signature could be processed successfully, false otherwise.
  void _writeTileHeaderSignature(
      bool debugFile, Tile tile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength(
          "###TileStart${tile.tileX},${tile.tileY}###"
              .padRight(MapFile.SIGNATURE_LENGTH_BLOCK, " "));
    }
  }

  void _writeZoomtable(Tile tile, Writebuffer writebuffer) {
    for (int queryZoomLevel = zoomlevelRange.zoomlevelMin;
        queryZoomLevel <= zoomlevelRange.zoomlevelMax;
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
  List<Poiholder> poiholders = [];

  Writebuffer? writebuffer;

  int count = 0;

  final String? languagesPreference;

  Poiinfo(this.languagesPreference);

  void setPoidata(PointOfInterest poi, List<Tagholder> tagholders) {
    Poiholder poiholder = Poiholder(poi, tagholders, languagesPreference);
    poiholders.add(poiholder);
    ++count;
  }

  bool contains(PointOfInterest poi) {
    return poiholders.firstWhereOrNull((test) => test.poi == poi) != null;
  }

  Writebuffer writePoidata(
      bool debugFile, double tileLatitude, double tileLongitude) {
    if (writebuffer != null) return writebuffer!;
    writebuffer = Writebuffer();
    for (Poiholder poiholder in poiholders) {
      writebuffer!.appendWritebuffer(
          poiholder.writePoidata(debugFile, tileLatitude, tileLongitude));
    }
    poiholders.clear();
    return writebuffer!;
  }
}

//////////////////////////////////////////////////////////////////////////////

class Wayinfo {
  List<Wayholder> wayholders = [];

  Writebuffer? writebuffer;

  int count = 0;

  String? languagesPreference;

  Wayinfo(this.languagesPreference);

  void setWaydata(Way way, List<Tagholder> tagholders) {
    Wayholder wayholder = Wayholder(way, tagholders, languagesPreference);
    wayholders.add(wayholder);
    ++count;
  }

  Wayholder? searchWayholder(Way way) {
    return wayholders.firstWhereOrNull((test) => test.way == way);
  }

  Writebuffer writeWaydata(
      bool debugFile, Tile tile, double tileLatitude, double tileLongitude) {
    if (writebuffer != null) return writebuffer!;
    writebuffer = Writebuffer();
    for (Wayholder wayholder in wayholders) {
      writebuffer!.appendWritebuffer(
          wayholder.writeWaydata(debugFile, tile, tileLatitude, tileLongitude));
    }
    wayholders.clear();
    return writebuffer!;
  }
}
