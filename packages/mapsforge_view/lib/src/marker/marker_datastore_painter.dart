import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/marker/marker.dart';
import 'package:mapsforge_view/src/marker/marker_datastore.dart';

class MarkerDatastorePainter extends CustomPainter {
  final MapPosition mapPosition;

  final MarkerDatastore datastore;

  MarkerDatastorePainter(this.mapPosition, this.datastore);

  @override
  void paint(Canvas canvas, Size size) {
    UiCanvas uiCanvas = UiCanvas(canvas, size);
    UiRenderContext renderContext = UiRenderContext(
      canvas: uiCanvas,
      reference: mapPosition.getCenter(),
      projection: mapPosition.projection,
      rotationRadian: mapPosition.rotationRadian,
    );
    for (Marker marker in datastore.askRetrieveMarkersToPaint()) {
      marker.render(renderContext);
    }
  }

  @override
  bool shouldRepaint(covariant MarkerDatastorePainter oldDelegate) {
    if (oldDelegate.datastore != datastore) return true;
    return false;
  }
}
