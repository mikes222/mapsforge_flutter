import 'package:mapsforge_flutter/src/marker/basicmarker.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';

class MarkerDataStore {
  final List<BasicMarker> markers = List();

  List<BasicMarker> getMarkers(BoundingBox boundary) {
    return markers;
  }
}
