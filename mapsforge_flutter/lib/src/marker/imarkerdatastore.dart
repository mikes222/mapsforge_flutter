import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';

abstract class IMarkerDataStore with ChangeNotifier {
  List<BasicMarker> getMarkers(
      GraphicFactory graphicFactory, BoundingBox boundary, int zoomLevel);

  List<BasicMarker> isTapped(
      MapViewPosition mapViewPosition, double tappedX, double tappedY);
}
