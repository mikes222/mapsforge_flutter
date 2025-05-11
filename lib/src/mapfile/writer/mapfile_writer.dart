import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_header_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_creator.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';

/// see https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md
class MapfileWriter {
  final _log = new Logger('MapfileWriter');

  final String filename;

  final List<Tagholder> poiTags = [];

  final List<Tagholder> wayTags = [];

  final SinkWithCounter _sink;

  final MapHeaderInfo mapHeaderInfo;

  final ZoomlevelRange _zoomlevelRange;

  final List<SubfileCreator> subfileCreators = [];

  MapfileWriter({required this.filename, required this.mapHeaderInfo})
      : _sink = SinkWithCounter(File(filename).openWrite()),
        _zoomlevelRange = mapHeaderInfo.zoomlevelRange {}

  Future<void> close() async {
    await _sink.close();
    // todo correct invalid data in file
    RandomAccessFile raf = await File(filename).open(mode: FileMode.writeOnlyAppend);
    // position of filesize
    Writebuffer writebuffer = Writebuffer();
    int length = await File(filename).length();
    writebuffer.appendInt8(length);
    await writebuffer.writeIntoAt(28, raf);
    await raf.close();
  }

  /// Writes the mapfile to the given sink.
  /// @param maxDeviationPixel The maximum deviation in pixels if we need to simplify a polygon because only 32767 points are supported in a polygon.
  Future<void> write(double maxDeviationPixel, int instanceCount) async {
    //createSubfiles();

    assert(subfileCreators.isNotEmpty);
//    assert(poiTags.isNotEmpty || wayTags.isNotEmpty);

    Writebuffer writebuffer = Writebuffer();
    for (SubfileCreator subfileCreator in subfileCreators) {
      subfileCreator.analyze(poiTags, wayTags, mapHeaderInfo.languagesPreference);
    }
    _writeTags(writebuffer, poiTags);
    _writeTags(writebuffer, wayTags);

    MapfileHeaderWriter mapfileHeaderWriter = MapfileHeaderWriter(mapHeaderInfo);
    Writebuffer writebufferHeader = mapfileHeaderWriter.write(writebuffer.length + 1 + 19 * subfileCreators.length);

    for (SubfileCreator subfileCreator in subfileCreators) {
      await subfileCreator.prepareTiles(mapHeaderInfo.debugFile, maxDeviationPixel, instanceCount);
    }
    // amount of zoom intervals
    writebuffer.appendInt1(subfileCreators.length);
    await _writeZoomIntervalConfiguration(writebuffer, writebufferHeader.length + writebuffer.length + 19 * subfileCreators.length);

    writebufferHeader.appendWritebuffer(writebuffer);
    writebufferHeader.writeToSink(_sink);

    for (SubfileCreator subfileCreator in subfileCreators) {
      // for each subfile, write the tile index header and entries
      Writebuffer writebuffer = subfileCreator.writeTileIndex(mapHeaderInfo.debugFile);
      writebuffer.writeToSink(_sink);
      await subfileCreator.writeTiles(mapHeaderInfo.debugFile, _sink);
      subfileCreator.dispose();
    }
  }

  Future<void> _writeZoomIntervalConfiguration(Writebuffer writebuffer, int headersize) async {
    int startAddress = headersize;
    for (SubfileCreator subfileCreator in subfileCreators) {
      writebuffer.appendInt1(subfileCreator.baseZoomLevel);
      writebuffer.appendInt1(subfileCreator.zoomlevelRange.zoomlevelMin);
      writebuffer.appendInt1(subfileCreator.zoomlevelRange.zoomlevelMax);
      // 8 byte start address
      writebuffer.appendInt8(startAddress);
      Writebuffer writebufferIndex = subfileCreator.writeTileIndex(mapHeaderInfo.debugFile);
      int length = await subfileCreator.getTilesLength(mapHeaderInfo.debugFile);
      // size of the sub-file as 8-byte LONG
      writebuffer.appendInt8(writebufferIndex.length + length);
      startAddress += writebufferIndex.length + length;
    }
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
