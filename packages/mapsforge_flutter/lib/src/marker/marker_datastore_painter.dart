import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/marker/marker.dart';
import 'package:mapsforge_flutter/src/marker/marker_datastore.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';

class MarkerDatastorePainter extends CustomPainter {
  final MapPosition mapPosition;

  final MarkerDatastore datastore;

  MarkerDatastorePainter(this.mapPosition, this.datastore) : super(repaint: datastore);

  @override
  void paint(Canvas canvas, Size size) {
    final session = PerformanceProfiler().startSession(category: "MarkerPainter.${datastore.runtimeType}");
    UiCanvas uiCanvas = UiCanvas(canvas, size);
    UiRenderContext renderContext = UiRenderContext(
      canvas: uiCanvas,
      reference: mapPosition.getCenter(),
      projection: mapPosition.projection,
      rotationRadian: mapPosition.rotationRadian,
    );
    Iterable<Marker> markers = datastore.askRetrieveMarkersToPaint();
    //print("Markerlenght: ${markers.length} for $datastore");
    for (Marker marker in markers) {
      marker.render(renderContext);
    }
    session.complete();
  }

  @override
  bool shouldRepaint(covariant MarkerDatastorePainter oldDelegate) {
    if (oldDelegate.datastore != datastore) return true;
    return false;
  }
}
