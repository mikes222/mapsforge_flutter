import 'package:mapsforge_flutter_core/model.dart';
import 'package:test/test.dart';

void main() {
  test("Test bounding box intersection with line", () async {
    // Beispiel 1: Linie schneidet das Rechteck
    var lineStart1 = const LatLong(47.0, 8.0);
    var lineEnd1 = const LatLong(49.0, 10.0);
    var rectangle1 = const BoundingBox(46.0, 7.0, 48.0, 9.0);
    print("Beispiel 1: Schneidet die Linie das Rechteck? ${rectangle1.intersectsLine(lineStart1, lineEnd1)}"); // Erwartet: true
    assert(rectangle1.intersectsLine(lineStart1, lineEnd1) == true);

    // Beispiel 2: Linie schneidet das Rechteck nicht
    var lineStart2 = const LatLong(50.0, 11.0); // lower left corner
    var lineEnd2 = const LatLong(52.0, 13.0); // upper right corner
    var rectangle2 = const BoundingBox(46.0, 7.0, 52.0, 10.0); // below the two points but the line would intersect beyond lineStart2
    print("Beispiel 2: Schneidet die Linie das Rechteck? ${rectangle2.intersectsLine(lineStart2, lineEnd2)}"); // Erwartet: false
    assert(rectangle2.intersectsLine(lineStart2, lineEnd2) == false);

    // Beispiel 3: Linie berührt das Rechteck (Endpunkt liegt auf der Kante)
    var lineStart3 = const LatLong(46.0, 7.0);
    var lineEnd3 = const LatLong(44.0, 5.0);
    var rectangle3 = const BoundingBox(46.0, 7.0, 48.0, 9.0);
    print("Beispiel 3: Schneidet die Linie das Rechteck? ${rectangle3.intersectsLine(lineStart3, lineEnd3)}"); // Erwartet: true

    // Beispiel 4: Linie geht durch das Rechteck
    var lineStart4 = const LatLong(45.0, 6.0);
    var lineEnd4 = const LatLong(49.0, 10.0);
    var rectangle4 = const BoundingBox(46.0, 7.0, 48.0, 9.0);
    print("Beispiel 4: Schneidet die Linie das Rechteck? ${rectangle4.intersectsLine(lineStart4, lineEnd4)}"); // Erwartet: true

    // Beispiel 5: Linie ist im Rechteck enthalten
    var lineStart5 = const LatLong(46.5, 7.5);
    var lineEnd5 = const LatLong(47.5, 8.5);
    var rectangle5 = const BoundingBox(46.0, 7.0, 48.0, 9.0);
    print("Beispiel 5: Schneidet die Linie das Rechteck? ${rectangle5.intersectsLine(lineStart5, lineEnd5)}"); // Erwartet: true
  });

  test("casino", () async {
    Tile tile = Tile(68235, 47798, 17, 0);
    List<ILatLong> points = [const LatLong(43.727158, 7.414372), const LatLong(43.727378, 7.414080)];

    print("Boundingbox: ${tile.getBoundingBox()}");
    bool result = tile.getBoundingBox().intersectsLine(points[0], points[1]);
    assert(result == true);
  });

  test("level2", () async {
    Tile tile = Tile(4265, 2989, 13, 0);
    List<ILatLong> points = [const LatLong(43.742195, 7.452435), const LatLong(43.516536, 7.500245)];

    print("Boundingbox: ${tile.getBoundingBox()}");
    bool result = tile.getBoundingBox().intersectsLine(points[0], points[1]);
    assert(result == true);
  });
}
