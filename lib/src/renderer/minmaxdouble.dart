import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';

class MinMaxDouble {
  double minX = double.maxFinite;
  double minY = double.maxFinite;
  double maxX = -double.maxFinite;
  double maxY = -double.maxFinite;

  MinMaxDouble(List<Mappoint> mp1) {
    mp1.forEach((element) {
      if (minX > element.x) minX = element.x;
      if (minY > element.y) minY = element.y;
      if (maxX < element.x) maxX = element.x;
      if (maxY < element.y) maxY = element.y;
    });
  }

  MinMaxDouble.empty() {}

  MinMaxDouble.zero()
      : minX = 0,
        minY = 0,
        maxX = 0,
        maxY = 0;

  void extendLatLong(List<ILatLong> mp1) {
    mp1.forEach((element) {
      if (minX > element.longitude) minX = element.longitude;
      if (minY > element.latitude) minY = element.latitude;
      if (maxX < element.longitude) maxX = element.longitude;
      if (maxY < element.latitude) maxY = element.latitude;
    });
  }

  MapRectangle getBoundary() {
    return MapRectangle(minX, minY, maxX, maxY);
  }

  @override
  String toString() {
    return 'MinMaxMappoint{minX: $minX, maxX: $maxX, minY: $minY, maxY: $maxY}';
  }
}
