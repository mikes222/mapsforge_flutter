import 'package:mapsforge_flutter/core.dart';

abstract class MapRect {
  double getLeft();

  double getTop();

  double getRight();

  double getBottom();

  MapRect offset(double x, double y);

  Mappoint getCenter();

  double getWidth();

  double getHeight();
}
