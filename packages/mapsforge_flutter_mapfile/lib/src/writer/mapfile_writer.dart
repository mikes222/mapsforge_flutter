import 'dart:core';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/mapfile_header_writer.dart';

/// The main class for writing a Mapsforge binary map file (`.map`).
///
/// This class orchestrates the entire process of creating a map file, from
/// writing the header and tag information to creating and filling the sub-files
/// with tile data.
///
/// See the official specification for more details:
/// https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md
class MapfileWriter {
  static final _log = Logger('MapfileWriter');

  final String filename;

  final SinkWithCounter _sink;

  final MapHeaderInfo mapHeaderInfo;

  final ZoomlevelRange _zoomlevelRange;

  final List<Subfile> subfiles;

  final TagholderModel model;

  MapfileWriter({required this.filename, required this.mapHeaderInfo, required this.subfiles, required this.model})
    : _sink = SinkWithCounter(File(filename).openWrite()),
      _zoomlevelRange = mapHeaderInfo.zoomlevelRange;

  /// Closes the writer and finalizes the map file.
  ///
  /// This method closes the underlying file sink and then re-opens the file to
  /// write the final, correct file size into the header, as this value is not
  /// known until all data has been written.
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

  /// Writes the complete map file structure to the file sink.
  ///
  /// [maxDeviationPixel] is the maximum allowed deviation in pixels when simplifying
  /// way geometries. This is used to prevent polygons from having more than 32767
  /// points, which is a limitation of the format.
  /// [instanceCount] is the number of parallel instances to use for tile processing.
  Future<void> write(double maxDeviationPixel, int instanceCount) async {
    //createSubfiles();

    assert(subfiles.isNotEmpty);
    //    assert(poiTags.isNotEmpty || wayTags.isNotEmpty);

    List<String> languagesPreferences = [];
    if (mapHeaderInfo.languagesPreference != null) languagesPreferences.addAll(mapHeaderInfo.languagesPreference!.split(","));
    // mapmodel should be aware of how many tags are needed and how often to being able to set the indexes accordingly.
    for (Subfile subfile in subfiles) {
      await subfile.countTags(model);
    }

    // after counting the tags we can set the indexes of each tag
    model.setIndexes();

    Writebuffer writebuffer = Writebuffer();
    _writePoiTags(writebuffer, model.poiTags);
    _writeWayTags(writebuffer, model.wayTags);

    MapfileHeaderWriter mapfileHeaderWriter = MapfileHeaderWriter(mapHeaderInfo);
    Writebuffer writebufferHeader = mapfileHeaderWriter.write(writebuffer.length + 1 + 19 * subfiles.length);

    // amount of zoom intervals
    writebuffer.appendInt1(subfiles.length);
    await _writeZoomIntervalConfiguration(writebuffer, writebufferHeader.length + writebuffer.length + 19 * subfiles.length, maxDeviationPixel, instanceCount);

    writebufferHeader.appendWritebuffer(writebuffer);
    writebufferHeader.writeToSink(_sink);
    writebuffer.clear();
    writebufferHeader.clear();

    for (Subfile subfile in subfiles) {
      // for each subfile, write the tile index header and entries
      Writebuffer writebuffer = subfile.writeTileIndex(mapHeaderInfo.debugFile);
      writebuffer.writeToSink(_sink);
      writebuffer.clear();
      await subfile.writeTiles(mapHeaderInfo.debugFile, _sink);
      subfile.dispose();
    }
  }

  Future<void> _writeZoomIntervalConfiguration(Writebuffer writebuffer, int headersize, double maxDeviationPixel, int instanceCount) async {
    int startAddress = headersize;
    for (Subfile subfile in subfiles) {
      writebuffer.appendInt1(subfile.baseZoomLevel);
      writebuffer.appendInt1(subfile.zoomlevelRange.zoomlevelMin);
      writebuffer.appendInt1(subfile.zoomlevelRange.zoomlevelMax);
      // 8 byte start address
      writebuffer.appendInt8(startAddress);

      await subfile.prepareTiles(mapHeaderInfo.debugFile, maxDeviationPixel, instanceCount);

      Writebuffer writebufferIndex = subfile.writeTileIndex(mapHeaderInfo.debugFile);
      int length = await subfile.getTilesLength(mapHeaderInfo.debugFile);
      // size of the sub-file as 8-byte LONG
      writebuffer.appendInt8(writebufferIndex.length + length);
      startAddress += writebufferIndex.length + length;
    }
  }

  void _writePoiTags(Writebuffer writebuffer, List<Tagholder> tagholders) {
    List<String> items = [];
    for (Tagholder tagholder in tagholders) {
      if (TagholderModel.isMapfilePoiTag(tagholder.key)) continue;
      assert(tagholder.index != null, "tagholder.index must not be null $tagholder");
      assert(tagholder.count > 0, "tagholder.count must be greater than 0 $tagholder");
      String value = "${tagholder.key}=${tagholder.value}";
      items.add(value);
    }
    writebuffer.appendInt2(items.length);
    for (String item in items) {
      writebuffer.appendString(item);
    }
  }

  void _writeWayTags(Writebuffer writebuffer, List<Tagholder> tagholders) {
    List<String> items = [];
    for (Tagholder tagholder in tagholders) {
      if (TagholderModel.isMapfileWayTag(tagholder.key)) continue;
      assert(tagholder.index != null, "tagholder.index must not be null $tagholder");
      assert(tagholder.count > 0, "tagholder.count must be greater than 0 $tagholder");
      String value = "${tagholder.key}=${tagholder.value}";
      items.add(value);
    }
    writebuffer.appendInt2(items.length);
    for (String item in items) {
      writebuffer.appendString(item);
    }
  }
}
