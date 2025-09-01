import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';
import 'package:test/test.dart';

void main() async {
  late Mapfile mapFile;

  setUpAll(() async {
    mapFile = await Mapfile.createFromFile(filename: "test/campus_level.map");
  });

  test("should return zoomlevel from mapfile", () async {
    expect(await mapFile.getStartZoomLevel(), 12);
  });

  test("should return startposition from mapfile", () async {
    expect(await mapFile.getStartPosition(), const LatLong(50.8138795, 12.928627500000001));
  });
}
