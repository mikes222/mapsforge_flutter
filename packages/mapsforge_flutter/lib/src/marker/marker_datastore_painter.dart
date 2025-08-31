import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/marker/marker.dart';
import 'package:mapsforge_flutter/src/marker/marker_datastore.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';

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
