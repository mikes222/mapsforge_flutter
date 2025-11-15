import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_path.dart';
import 'package:mapsforge_flutter_renderer/src/util/path_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  testWidgets('Tests dashes', (WidgetTester tester) async {
    List<double> strokes = [7.875, 7.875];
    List<Pointinfo> points = [];
    points.add(Pointinfo(true, 163.9, 65.5));
    points.add(Pointinfo(false, 163.9, 65.5));
    points.add(Pointinfo(false, 160.7, 87.9));
    points.add(Pointinfo(false, 169.2, 107.3));
    points.add(Pointinfo(false, 202.7, 114.1));
    points.add(Pointinfo(false, 180.4, 136.3));
    points.add(Pointinfo(false, 179.8, 148.9));

    PathHelper.calculateDashes(points, strokes);

    String debug = "";
    for (int i = 0; i < points.length; i++) {
      if (i < points.length - 1) {
        double distance = sqrt(
          (points[i].offset.dx - points[i + 1].offset.dx) * (points[i].offset.dx - points[i + 1].offset.dx) +
              (points[i].offset.dy - points[i + 1].offset.dy) * (points[i].offset.dy - points[i + 1].offset.dy),
        );
        debug += distance.toStringAsFixed(1);
        debug += " - ";
      }
    }
    print(debug);

    // *7.9* - 7.9 - *6.8* - 0.0 - *1.1* - 7.9 - *7.9* - 7.0 - *7.9* - 7.9 - *7.9* - 6.8 - *7.9* - 7.9 - *7.9* - 7.7 - *7.9* -
  });
}
