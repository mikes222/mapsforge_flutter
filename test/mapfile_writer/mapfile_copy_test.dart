import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_creator.dart';

import '../testassetbundle.dart';

main() async {
  test("MultimapDatastore without maps", () async {
    _initLogging();
    DisplayModel displayModel = DisplayModel();

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    String content = await TestAssetBundle().loadString("lightrender.xml");
    renderThemeBuilder.parseXml(displayModel, content);
    RenderTheme renderTheme = renderThemeBuilder.build();

    MapFile mapFile = await MapFile.from(
        TestAssetBundle().correctFilename("monaco.map"),
        null,
        null); //Map that contains part of the Canpus Reichehainer Straße
    // open the mapFile
    BoundingBox? boundingBox = await mapFile.getBoundingBox();
    MapHeaderInfo mapHeaderInfo = MapHeaderInfo(
      boundingBox: boundingBox,
      poiTags: [],
      tilePixelSize: 256,
      wayTags: [],
      debugFile: false,
      mapDate: mapFile.getMapHeaderInfo().mapDate,
      startPosition: mapFile.getMapHeaderInfo().startPosition,
      startZoomLevel: mapFile.getMapHeaderInfo().startZoomLevel,
      languagesPreference: mapFile.getMapHeaderInfo().languagesPreference,
      comment: mapFile.getMapHeaderInfo().comment,
      createdBy: mapFile.getMapHeaderInfo().createdBy,
    );
    mapFile.getMapFileInfo().subFileParameters.forEach((key, value) {
      //print("Key: $key, value: $value");
    });

    MapfileWriter mapfileWriter =
        MapfileWriter(filename: "test.map", mapHeaderInfo: mapHeaderInfo);

    List<SubfileCreator> subfileParameters = [];
    SubfileCreator subfileparameterCreator = SubfileCreator(
        baseZoomLevel: 5,
        zoomLevelMax: 7,
        zoomLevelMin: 0,
        debugFile: mapHeaderInfo.debugFile,
        boundingBox: boundingBox);
    subfileParameters.add(subfileparameterCreator);
    await processSubfile(
        mapFile, mapfileWriter, subfileparameterCreator, boundingBox);

    subfileparameterCreator = SubfileCreator(
        baseZoomLevel: 10,
        zoomLevelMax: 11,
        zoomLevelMin: 8,
        debugFile: mapHeaderInfo.debugFile,
        boundingBox: boundingBox);
    subfileParameters.add(subfileparameterCreator);
    await processSubfile(
        mapFile, mapfileWriter, subfileparameterCreator, boundingBox);

    subfileparameterCreator = SubfileCreator(
        baseZoomLevel: 14,
        zoomLevelMax: 21,
        zoomLevelMin: 12,
        debugFile: mapHeaderInfo.debugFile,
        boundingBox: boundingBox);
    subfileParameters.add(subfileparameterCreator);
    await processSubfile(
        mapFile, mapfileWriter, subfileparameterCreator, boundingBox);

    // now start with writing the actual file
    mapfileWriter.write(subfileParameters);
    await mapfileWriter.close();
  });
}

Future<void> processSubfile(MapFile mapfile, MapfileWriter mapfileWriter,
    SubfileCreator subfileparameterCreator, BoundingBox boundingBox) async {
  for (int zoomLevel = subfileparameterCreator.zoomLevelMin;
      zoomLevel <= subfileparameterCreator.zoomLevelMax;
      zoomLevel++) {
    MercatorProjection projection = MercatorProjection.fromZoomlevel(zoomLevel);
    int minTileX = projection.longitudeToTileX(boundingBox.minLongitude);
    int maxTileX = projection.longitudeToTileX(boundingBox.maxLatitude);
    int minTileY = projection.latitudeToTileY(boundingBox.maxLatitude);
    int maxTileY = projection.latitudeToTileY(boundingBox.minLatitude);
    Tile upperLeft = new Tile(minTileX, minTileY, zoomLevel, 0);
    Tile lowerRight = new Tile(maxTileX, maxTileY, zoomLevel, 0);
    DatastoreReadResult mapReadResult =
        await mapfile.readMapData(upperLeft, lowerRight);
    mapfileWriter.preparePoidata(
        subfileparameterCreator, zoomLevel, mapReadResult.pointOfInterests);
    mapfileWriter.prepareWays(
        subfileparameterCreator, zoomLevel, mapReadResult.ways);
    // print(
    //     "${projection.longitudeToTileX(boundingBox.minLongitude)} to ${projection.longitudeToTileX(boundingBox.maxLongitude)}, ${projection.latitudeToTileY(boundingBox.maxLatitude)} to ${projection.latitudeToTileY(boundingBox.minLatitude)}");
  }
}

//////////////////////////////////////////////////////////////////////////////

void _initLogging() {
// Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
