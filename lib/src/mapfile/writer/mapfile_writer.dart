import 'dart:core';
import 'dart:io';
import 'dart:math' as Math;

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_header_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_creator.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/zoomlevel_creator.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';

/// see https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md
class MapfileWriter {
  final String filename;

  final List<Tagholder> poiTags = [];

  final List<Tagholder> wayTags = [];

  final MapfileSink sink;

  final MapHeaderInfo mapHeaderInfo;

  final ZoomlevelRange zoomlevelRange;

  final Map<int, ZoomlevelCreator> zoomlevelCreators = {};

  final List<SubfileCreator> subfileCreators = [];

  MapfileWriter({required this.filename, required this.mapHeaderInfo})
      : sink = MapfileSink(File(filename).openWrite()),
        zoomlevelRange = mapHeaderInfo.zoomlevelRange {
    for (int zoomlevel = zoomlevelRange.zoomlevelMin;
        zoomlevel <= zoomlevelRange.zoomlevelMax;
        ++zoomlevel) {
      zoomlevelCreators[zoomlevel] = ZoomlevelCreator(
          zoomlevel: zoomlevel, parent: zoomlevelCreators[zoomlevel - 1]);
    }
  }

  Future<void> close() async {
    await sink.close();
    // todo correct invalid data in file
    RandomAccessFile raf =
        await File(filename).open(mode: FileMode.writeOnlyAppend);
    // position of filesize
    Writebuffer writebuffer = Writebuffer();
    int length = await File(filename).length();
    writebuffer.appendInt8(length);
    await writebuffer.writeIntoAt(28, raf);
    await raf.close();
  }

  void createSubfiles() {
    zoomlevelCreators.forEach((zoomlevel, zoomlevelCreator) {
      print("${zoomlevelCreator}");
    });

    int wayCount = zoomlevelCreators.values.last.wayCount;
    int countSubfiles =
        ((zoomlevelRange.zoomlevelMax - zoomlevelRange.zoomlevelMin) / 3)
            .floor();
    if (countSubfiles > 3)
      countSubfiles = 3;
    else if (countSubfiles < 1) countSubfiles = 1;
    int wayCountPerSubfile = (wayCount / 2).ceil();
    print(
        "We will write $countSubfiles subfiles with $wayCountPerSubfile for the largest subfile");

    final List<SubfileSimulator> subfileSimulators = [];

    int zoomLevelMax = this.zoomlevelRange.zoomlevelMax;
    for (int i = 0; i < countSubfiles; ++i) {
      int zoomLevelMin =
          Math.max(this.zoomlevelRange.zoomlevelMin, zoomLevelMax - 2);
      while (zoomLevelMin > this.zoomlevelRange.zoomlevelMin &&
          zoomlevelCreators[zoomLevelMin]!.wayCount > wayCountPerSubfile) {
        --zoomLevelMin;
      }
      int baseZoomlevel = zoomLevelMin + 1;
      if (baseZoomlevel >= zoomLevelMax) {
        baseZoomlevel = zoomLevelMin;
      }
      SubfileSimulator subfileSimulator = SubfileSimulator(
          baseZoomlevel: baseZoomlevel,
          zoomLevelMin: zoomLevelMin,
          zoomLevelMax: zoomLevelMax);

      for (int zoomlevel = zoomLevelMin;
          zoomlevel <= zoomLevelMax;
          ++zoomlevel) {
        ZoomlevelCreator zoomlevelCreator = zoomlevelCreators[zoomlevel]!;
        subfileSimulator.addPoidata(zoomlevel,
            zoomlevelCreator.poiholders.map((toElement) => toElement).toList());
        subfileSimulator.addWaydata(zoomlevel,
            zoomlevelCreator.wayholders.map((toElement) => toElement).toList());
      }
      subfileSimulator.finalize();

      subfileSimulators.insert(0, subfileSimulator);
      zoomLevelMax = zoomLevelMin - 1;
      wayCountPerSubfile = (wayCountPerSubfile / 2).ceil();
      if (i == countSubfiles - 2) wayCountPerSubfile = 0;
    }

    for (SubfileSimulator subfileSimulator in subfileSimulators) {
      print(subfileSimulator);
    }

    // for (SubfileSimulator subfileSimulator in subfileSimulators) {
    //   SubfileCreator subfileCreator = SubfileCreator(
    //       baseZoomLevel: subfileSimulator.baseZoomlevel,
    //       zoomlevelRange: ZoomlevelRange(
    //           subfileSimulator.zoomLevelMin, subfileSimulator.zoomLevelMax),
    //       boundingBox: mapHeaderInfo.boundingBox);
    //   for (int zoomlevel = subfileSimulator.zoomLevelMin;
    //       zoomlevel <= subfileSimulator.zoomLevelMax;
    //       ++zoomlevel) {
    //     subfileCreator.addPoidata(subfileSimulator
    //         subfileSimulator.zoomSimulators[zoomlevel]!.poiholders
    //             .map((toElement) => toElement)
    //             .toList(),
    //         poiTags);
    //     subfileCreator.addWaydata(
    //         subfileSimulator.zoomSimulators[zoomlevel]!.wayholders
    //             .map((toElement) => toElement)
    //             .toList(),
    //         wayTags);
    //   }
    //   subfileCreators.add(subfileCreator);
    // }
  }

  void write() {
    //createSubfiles();

    assert(subfileCreators.isNotEmpty);
//    assert(poiTags.isNotEmpty || wayTags.isNotEmpty);

    Writebuffer writebuffer = Writebuffer();
    _writeTags(writebuffer, poiTags);
    _writeTags(writebuffer, wayTags);

    MapfileHeaderWriter mapfileHeaderWriter =
        MapfileHeaderWriter(mapHeaderInfo);
    Writebuffer writebufferHeader = mapfileHeaderWriter
        .write(writebuffer.length + 1 + 19 * subfileCreators.length);

    // amount of zoom intervals
    writebuffer.appendInt1(subfileCreators.length);
    _writeZoomIntervalConfiguration(
        writebuffer,
        writebufferHeader.length +
            writebuffer.length +
            19 * subfileCreators.length);

    writebufferHeader.appendWritebuffer(writebuffer);
    writebufferHeader.writeToSink(sink);

    for (SubfileCreator subfileCreator in subfileCreators) {
      // for each subfile, write the tile index header and entries
      Writebuffer writebuffer =
          subfileCreator.writeTileIndex(mapHeaderInfo.debugFile);
      writebuffer.writeToSink(sink);
      writebuffer = subfileCreator.writeTiles(mapHeaderInfo.debugFile);
      writebuffer.writeToSink(sink);
    }
  }

  void _writeZoomIntervalConfiguration(
      Writebuffer writebuffer, int headersize) {
    int startAddress = headersize;
    subfileCreators.forEach((SubfileCreator subFileParameter) {
      writebuffer.appendInt1(subFileParameter.baseZoomLevel);
      writebuffer.appendInt1(subFileParameter.zoomlevelRange.zoomlevelMin);
      writebuffer.appendInt1(subFileParameter.zoomlevelRange.zoomlevelMax);
      // 8 byte start address
      writebuffer.appendInt8(startAddress);
      Writebuffer writebufferIndex =
          subFileParameter.writeTileIndex(mapHeaderInfo.debugFile);
      Writebuffer writebufferTiles =
          subFileParameter.writeTiles(mapHeaderInfo.debugFile);
      // size of the sub-file as 8-byte LONG
      writebuffer.appendInt8(writebufferIndex.length + writebufferTiles.length);
      startAddress += writebufferIndex.length + writebufferTiles.length;
    });
  }

  void _writeTags(Writebuffer writebuffer, List<Tagholder> tagholders) {
    tagholders.sort((a, b) => b.count - a.count);
    tagholders.forEachIndexed((index, tagholder) {
      tagholder.index = index;
    });
    //tagholders.forEach((action) => print("$action"));
    writebuffer.appendInt2(tagholders.length);
    for (Tagholder tagholder in tagholders) {
      String value = "${tagholder.tag.key}=${tagholder.tag.value}";
      writebuffer.appendString(value);
    }
  }

  void preparePoidata(int zoomlevel, List<PointOfInterest> pois) {
    ZoomlevelCreator zoomlevelCreator = zoomlevelCreators[zoomlevel]!;
    zoomlevelCreator.addPoidata(pois);
  }

  void prepareWays(int zoomlevel, List<Way> ways) {
    ZoomlevelCreator zoomlevelCreator = zoomlevelCreators[zoomlevel]!;
    zoomlevelCreator.addWaydata(ways);
  }
}

//////////////////////////////////////////////////////////////////////////////

class MapfileSink {
  final IOSink sink;

  int written = 0;

  MapfileSink(this.sink);

  Future<void> close() async {
    await sink.close();
  }

  void add(List<int> buffer) {
    sink.add(buffer);
    written += buffer.length;
  }
}

//////////////////////////////////////////////////////////////////////////////

class Tagholder {
  // how often is the tag used. We will use this for sorting tags
  int count = 0;

  // the index of the tag after sorting
  int? index;

  final Tag tag;

  Tagholder(this.tag);

  @override
  String toString() {
    return 'Tagholder{count: $count, index: $index, tag: $tag}';
  }
}
