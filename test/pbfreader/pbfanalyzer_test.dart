import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffermemory.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/pbfreader/pbf_analyzer.dart';

import '../testassetbundle.dart';

main() async {
  test("Read pbf file from memory", () async {
    _initLogging();
    ByteData byteData = await TestAssetBundle().load("monaco-latest.osm.pbf");
    Uint8List data = byteData.buffer.asUint8List();
    ReadbufferSource readbufferSource = ReadbufferMemory(data);
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer();
    await pbfAnalyzer.analyze(readbufferSource, data.length);
    pbfAnalyzer.statistics();
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
