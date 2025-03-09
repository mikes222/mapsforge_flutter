import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_header_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_creator.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';

/// see https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md
class MapfileWriter {
  final String filename;

  final List<Tagholder> poiTags = [];

  final List<Tagholder> wayTags = [];

  final MapfileSink _sink;

  final MapHeaderInfo mapHeaderInfo;

  final ZoomlevelRange _zoomlevelRange;

  final List<SubfileCreator> subfileCreators = [];

  MapfileWriter({required this.filename, required this.mapHeaderInfo})
      : _sink = MapfileSink(File(filename).openWrite()),
        _zoomlevelRange = mapHeaderInfo.zoomlevelRange {}

  Future<void> close() async {
    await _sink.close();
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

  void write() {
    //createSubfiles();

    assert(subfileCreators.isNotEmpty);
//    assert(poiTags.isNotEmpty || wayTags.isNotEmpty);

    Writebuffer writebuffer = Writebuffer();
    for (SubfileCreator subfileCreator in subfileCreators) {
      subfileCreator.analyze(
          poiTags, wayTags, mapHeaderInfo.languagesPreference);
    }
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
    writebufferHeader.writeToSink(_sink);

    for (SubfileCreator subfileCreator in subfileCreators) {
      // for each subfile, write the tile index header and entries
      Writebuffer writebuffer =
          subfileCreator.writeTileIndex(mapHeaderInfo.debugFile);
      writebuffer.writeToSink(_sink);
      writebuffer = subfileCreator.writeTiles(mapHeaderInfo.debugFile);
      writebuffer.writeToSink(_sink);
    }
  }

  void _writeZoomIntervalConfiguration(
      Writebuffer writebuffer, int headersize) {
    int startAddress = headersize;
    subfileCreators.forEach((SubfileCreator subfileCreator) {
      writebuffer.appendInt1(subfileCreator.baseZoomLevel);
      writebuffer.appendInt1(subfileCreator.zoomlevelRange.zoomlevelMin);
      writebuffer.appendInt1(subfileCreator.zoomlevelRange.zoomlevelMax);
      // 8 byte start address
      writebuffer.appendInt8(startAddress);
      Writebuffer writebufferIndex =
          subfileCreator.writeTileIndex(mapHeaderInfo.debugFile);
      Writebuffer writebufferTiles =
          subfileCreator.writeTiles(mapHeaderInfo.debugFile);
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
