import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/projection/projection.dart';
import 'package:mapsforge_flutter/src/projection/scalefactor.dart';

main() {
  test("Scalefactor", () {
    expect(Scalefactor.fromZoomlevel(4).scalefactor, 16);
    expect(Scalefactor.fromScalefactor(16).zoomlevel, 4);
  });

  test("MercatorProjection", () {
    int zoomLevel = 4; // 1, 2, 4, 8, 16 tiles per zoomlevel
    MercatorProjection projection = MercatorProjection.fromZoomlevel(zoomLevel);
    expect(projection.tileYToLatitude(0), Projection.LATITUDE_MAX);
    expect(projection.tileYToLatitude(7), 21.943045533438166);
    expect(projection.tileYToLatitude(8), 0);
    expect(projection.tileYToLatitude(15), -82.67628497834903);
    expect(projection.tileYToLatitude(16), Projection.LATITUDE_MIN);

    expect(projection.tileXToLongitude(0), -180);
    expect(projection.tileXToLongitude(7), -22.5);
    expect(projection.tileXToLongitude(8), 0);
    expect(projection.tileXToLongitude(15), 157.5);
    expect(projection.tileXToLongitude(16), 180);

    expect(projection.longitudeToTileX(7.4262), 8); // lat/lon: 43.7399/7.4262;
    expect(projection.latitudeToTileY(43.7399), 5);
  });
}
