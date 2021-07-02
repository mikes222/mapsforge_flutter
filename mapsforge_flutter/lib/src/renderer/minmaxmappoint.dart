import 'package:mapsforge_flutter/src/model/mappoint.dart';

class MinMaxMappoint {
  double minX = 10000000;
  double minY = 10000000;
  double maxX = -10000000;
  double maxY = -10000000;
  MinMaxMappoint(List<Mappoint> mp1) {
    mp1.forEach((element) {
      if (minX > element.x) minX = element.x;
      if (minY > element.y) minY = element.y;
      if (maxX < element.x) maxX = element.x;
      if (maxY < element.y) maxY = element.y;
    });
  }

  @override
  String toString() {
    return 'MinMaxMappoint{minX: $minX, maxX: $maxX, minY: $minY, maxY: $maxY}';
  }
}
