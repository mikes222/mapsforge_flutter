import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile_header_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/subfile_creator.dart';
import 'package:mapsforge_flutter/src/mapfile/writebuffer.dart';

/// see https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md
class MapfileWriter {
  final String filename;

  final List<Tagholder> poiTags = [];

  final List<Tagholder> wayTags = [];

  final MapfileSink sink;

  final MapHeaderInfo mapHeaderInfo;

  MapfileWriter({required this.filename, required this.mapHeaderInfo})
      : sink = MapfileSink(File(filename).openWrite()) {}

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

  void write(List<SubfileCreator> subfileParameters) {
    assert(poiTags.isNotEmpty || wayTags.isNotEmpty);
    assert(subfileParameters.isNotEmpty);

    Writebuffer writebuffer = Writebuffer();
    _writeTags(writebuffer, poiTags);
    _writeTags(writebuffer, wayTags);

    MapfileHeaderWriter mapfileHeaderWriter =
        MapfileHeaderWriter(mapHeaderInfo);
    Writebuffer writebufferHeader = mapfileHeaderWriter
        .write(writebuffer.length + 1 + 19 * subfileParameters.length);

    // amount of zoom intervals
    writebuffer.appendInt1(subfileParameters.length);
    _writeZoomIntervalConfiguration(
        writebuffer,
        subfileParameters,
        writebufferHeader.length +
            writebuffer.length +
            19 * subfileParameters.length);

    writebufferHeader.appendWritebuffer(writebuffer);
    writebufferHeader.writeToSink(sink);

    for (SubfileCreator subfileparameterCreator in subfileParameters) {
      // for each subfile, write the tile index header and entries
      Writebuffer writebuffer = subfileparameterCreator.writeTileIndex();
      writebuffer.writeToSink(sink);
      writebuffer = subfileparameterCreator.writeTiles();
      writebuffer.writeToSink(sink);
    }
  }

  void _writeZoomIntervalConfiguration(Writebuffer writebuffer,
      List<SubfileCreator> subfileParameters, int headersize) {
    int startAddress = headersize;
    subfileParameters.forEach((SubfileCreator subFileParameter) {
      writebuffer.appendInt1(subFileParameter.baseZoomLevel);
      writebuffer.appendInt1(subFileParameter.zoomLevelMin);
      writebuffer.appendInt1(subFileParameter.zoomLevelMax);
      // 8 byte start address
      writebuffer.appendInt8(startAddress);
      Writebuffer writebufferIndex = subFileParameter.writeTileIndex();
      Writebuffer writebufferTiles = subFileParameter.writeTiles();
      // size of the sub-file as 8-byte LONG
      writebuffer.appendInt8(writebufferIndex.length + writebufferTiles.length);
      startAddress += writebufferIndex.length + writebufferTiles.length;
    });
  }

  void _writeTags(Writebuffer writebuffer, List<Tagholder> tagholders) {
    tagholders.sort((a, b) => a.count - b.count);
    tagholders.forEachIndexed((index, tagholder) {
      tagholder.index = index;
    });
    writebuffer.appendInt2(tagholders.length);
    for (Tagholder tagholder in tagholders) {
      String value = "${tagholder.tag.key}=${tagholder.tag.value}";
      writebuffer.appendString(value);
    }
  }

  void preparePoidata(SubfileCreator subfileCreator, Tile basetile,
      int zoomlevel, List<PointOfInterest> pois) {
    subfileCreator.addPoidata(basetile, zoomlevel, pois, poiTags);
  }

  void prepareWays(SubfileCreator subfileCreator, Tile basetile, int zooomlevel,
      List<Way> ways) {
    subfileCreator.addWaydata(basetile, zooomlevel, ways, wayTags);
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
}
