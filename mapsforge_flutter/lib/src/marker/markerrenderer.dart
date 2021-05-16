import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/markerdatastore.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

import 'basicmarker.dart';
import 'markercontext.dart';

///
/// The MarkerRenderer holds a MarkerDatastore and renders it on screen.
///
class MarkerRenderer {
  static final _log = new Logger('MarkerRenderer');

  final GraphicFactory graphicFactory;

  final MarkerDataStore dataStore;

  final ViewModel viewModel;

  MarkerRenderer(this.graphicFactory, this.viewModel, this.dataStore);

  void draw(FlutterCanvas flutterCanvas, MapViewPosition position) {
    //flutterCanvas.resetClip();
    flutterCanvas.setClip(0, 0, viewModel.viewDimension!.width.round(), viewModel.viewDimension!.height.round());
    MarkerContext context = MarkerContext(flutterCanvas, graphicFactory, position);
    List<BasicMarker> markers =
        dataStore.getMarkers(graphicFactory, position.calculateBoundingBox(viewModel.viewDimension!), position.zoomLevel);
    // _log.info("Drawing ${markers?.length ?? -1} markers");
    if (markers != null && markers.length > 0) {
      markers.forEach((element) {
        element.render(context);
      });
    }

    dataStore.resetRepaint();
  }

  bool shouldRepaint() {
    return dataStore.needsRepaint;
  }

  ///
  /// see markerPainter
  ///
  void addListener(listener) {
    dataStore.addListener(listener);
  }

  ///
  /// see markerPainter
  ///
  void removeListener(listener) {
    dataStore.removeListener(listener);
  }
}
