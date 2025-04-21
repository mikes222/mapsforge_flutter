import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapfile_converter/pbf/pbf_reader.dart';
import 'package:mapsforge_flutter/src/mapfile/readbufferfile.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffermemory.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';

import '../testassetbundle.dart';

main() async {
  test("Read pbf file from memory", () async {
    _initLogging();
    ByteData byteData = await TestAssetBundle().load("monaco-latest.osm.pbf");
    Uint8List data = byteData.buffer.asUint8List();
    ReadbufferSource readbufferSource = ReadbufferMemory(data);
    PbfReader pbfReader = PbfReader();
    await pbfReader.open(readbufferSource);
    while (readbufferSource.getPosition() < data.length) {
      OsmData blockData = await pbfReader.readBlobData(readbufferSource);
      print(blockData);
    }
  });

  test("Read pbf file", () async {
    _initLogging();
    ReadbufferSource readbufferSource = ReadbufferFile(TestAssetBundle().correctFilename("monaco-latest.osm.pbf"));
    int length = await readbufferSource.length();
    PbfReader pbfReader = PbfReader();
    await pbfReader.open(readbufferSource);
    while (readbufferSource.getPosition() < length) {
      OsmData blockData = await pbfReader.readBlobData(readbufferSource);
      print(blockData);
    }
  });

  test("Skip pbf file from memory", () async {
    _initLogging();
    ByteData byteData = await TestAssetBundle().load("monaco-latest.osm.pbf");
    Uint8List data = byteData.buffer.asUint8List();
    ReadbufferSource readbufferSource = ReadbufferMemory(data);
    PbfReader pbfReader = PbfReader();
    await pbfReader.open(readbufferSource);
    while (readbufferSource.getPosition() < data.length) {
      await pbfReader.skipBlob(readbufferSource);
      print("Skipped block");
    }
  });
}

//////////////////////////////////////////////////////////////////////////////

void _initLogging() {
  // Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
