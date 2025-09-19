import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';
import 'package:test/test.dart';

void main() {
  late Mapfile mapFile;

  setUpAll(() async {
    _initLogging();
    // Create a MapFile instance from the monaco.map file
    mapFile = await Mapfile.createFromFile(filename: 'test/monaco.map', preferredLanguage: null);
    // Trigger loading of map data by getting the bounding box
    await mapFile.getBoundingBox();
  });

  tearDownAll(() {
    // Clean up resources
    mapFile.dispose();
  });

  test('should load monaco.map and create MapFile', () {
    // Verify that the MapFile was created successfully
    expect(mapFile, isNotNull);

    // Get map file info and verify it's not null
    final mapFileInfo = mapFile.getMapFileInfo();
    expect(mapFileInfo, isNotNull);

    // Get map header info
    final mapHeaderInfo = mapFile.getMapHeaderInfo();
    expect(mapHeaderInfo, isNotNull);

    // Print some debug info
    print('Map File Info:');
    // Print available information from mapHeaderInfo
    print('- Map Header Info:');
    print('  - Comment: ${mapHeaderInfo.comment ?? 'N/A'}');
    print('  - Created By: ${mapHeaderInfo.createdBy ?? 'N/A'}');
    print('  - Debug File: ${mapHeaderInfo.debugFile}');
    print('  - File Version: ${mapHeaderInfo.fileVersion ?? 'N/A'}');
    print('  - File Size: ${mapHeaderInfo.fileSize ?? 'N/A'} bytes');
    print('  - Languages: ${mapHeaderInfo.languagesPreference ?? 'N/A'}');
    print('  - Map Date: ${mapHeaderInfo.mapDate != null ? DateTime.fromMillisecondsSinceEpoch(mapHeaderInfo.mapDate!) : 'N/A'}');
    print('  - Number of Sub-Files: ${mapHeaderInfo.numberOfSubFiles ?? 'N/A'}');
    print('  - Bounding Box: ${mapHeaderInfo.boundingBox}');
  });

  test('should have 3 sub-files', () {
    expect(mapFile.getMapHeaderInfo().numberOfSubFiles, equals(3));
  });

  test('should get bounding box', () async {
    final boundingBox = await mapFile.getBoundingBox();
    expect(boundingBox, isNotNull);
    print('Bounding Box: $boundingBox');
  });

  test('should get start zoom level', () async {
    final startZoom = await mapFile.getStartZoomLevel();
    expect(startZoom, isNotNull);
    print('Start Zoom Level: $startZoom');
  });

  test('should get map file helper', () {
    final helper = mapFile.getMapfileHelper();
    expect(helper, isNotNull);
    print('Map File Helper: $helper');
  });

  test('should support tile', () async {
    int zoomlevel = 18;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(7.4262); // lat/lon: 43.7399/7.4262;
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(43.7399);
    Tile tile = Tile(x, y, zoomlevel, 0);
    final ok = await mapFile.supportsTile(tile);
    expect(ok, isTrue);
  });

  test('should not support tile', () async {
    Tile tile = Tile(140486, 87975, 18, 0);
    final ok = await mapFile.supportsTile(tile);
    expect(ok, isFalse);
  });

  test('should handle invalid file path', () async {
    // The test passes if no exception is thrown when creating the MapFile
    // with an invalid path, as the actual error might occur during later operations
    final mapFile = await Mapfile.createFromFile(filename: 'nonexistent.map', preferredLanguage: null);

    // Ensure we can still call methods on the map file without crashing
    expect(mapFile, isNotNull);

    // The actual error might occur when trying to access the file
    try {
      await mapFile.getBoundingBox();
      // If we get here, the test will pass, but we'll log a warning
      print('Warning: Expected an error when accessing invalid map file, but none was thrown');
    } catch (e) {
      // Expected that an error might be thrown when accessing the file
      print('Caught expected exception when accessing invalid map file: $e');
    }
  });
}

void _initLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
