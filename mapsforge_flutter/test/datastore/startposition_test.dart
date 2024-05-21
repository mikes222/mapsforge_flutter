import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile.dart';

import '../testassetbundle.dart';

///
/// flutter test --update-goldens
///
///
main() async {
  //create a mapfile from .map
  MapFile mapFile = await MapFile.from(
      TestAssetBundle().correctFilename("campus_level.map"),
      null,
      null); //Map that contains part of the Canpus Reichehainer Straße

  /////////////////////////////////////////////////////////////////////////////

  test("zoomlevel", () async {
    expect(await mapFile.getStartZoomLevel(), 12);
  });

  test("startposition", () async {
    expect(await mapFile.getStartPosition(),
        const LatLong(50.8138795, 12.928627500000001));
  });
}
