import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';
import 'package:test/test.dart';

void main() {
  late Rendertheme renderTheme;

  setUpAll(() async {
    _initLogging();
    renderTheme = await RenderThemeBuilder.createFromFile("test/defaultrender.xml");
  });

  test('should return zoomlevel range for point of interest', () {
    PointOfInterest pointOfInterest = PointOfInterest(0, [Tag("place", "village")], LatLong(0, 0));
    ZoomlevelRange? range = renderTheme.getZoomlevelRangeNode(pointOfInterest);
    expect(range.toString(), "ZoomlevelRange{12 - 25}");
  });
}

void _initLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
