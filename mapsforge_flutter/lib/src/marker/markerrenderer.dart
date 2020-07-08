import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/markerdatastore.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/model/mapviewdimension.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

import 'basicmarker.dart';
import 'markercontext.dart';

class MarkerRenderer {
  final GraphicFactory graphicFactory;

  final MarkerDataStore dataStore;

  final DisplayModel displayModel;

  MarkerRenderer(this.graphicFactory, this.displayModel, this.dataStore);

  Future<void> initResources(MapViewDimension mapViewDimension, MapViewPosition position) async {
    List<BasicMarker> markers = dataStore.getMarkers(position.calculateBoundingBox(mapViewDimension.getDimension()), position.zoomLevel);
    if (markers != null && markers.length > 0) {
      for (BasicMarker marker in markers) {
        marker.initResources(graphicFactory);
      }
    }
  }

  void draw(FlutterCanvas flutterCanvas, MapViewDimension mapViewDimension, MapViewPosition position) {
    flutterCanvas.resetClip();
    flutterCanvas.setClip(0, 0, mapViewDimension.getDimension().width.round(), mapViewDimension.getDimension().height.round());
    MarkerContext context = MarkerContext(flutterCanvas, graphicFactory, position);
    List<BasicMarker> markers = dataStore.getMarkers(position.calculateBoundingBox(mapViewDimension.getDimension()), position.zoomLevel);
    if (markers != null && markers.length > 0) {
      for (BasicMarker marker in markers) {
        marker.renderNode(context);
      }
    }

    dataStore.resetRepaint();
  }

  bool shouldRepaint() {
    return dataStore.needsRepaint;
  }
}
