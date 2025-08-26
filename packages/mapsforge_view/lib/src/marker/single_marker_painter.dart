import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/marker/marker.dart';

class SingleMarkerPainter extends CustomPainter {
  final MapPosition mapPosition;

  final Marker marker;

  SingleMarkerPainter(this.mapPosition, this.marker);

  @override
  void paint(Canvas canvas, Size size) {
    UiCanvas uiCanvas = UiCanvas(canvas, size);
    UiRenderContext renderContext = UiRenderContext(
      canvas: uiCanvas,
      reference: mapPosition.getCenter(),
      projection: mapPosition.projection,
      rotationRadian: mapPosition.rotationRadian,
    );
    marker.render(renderContext);
  }

  @override
  bool shouldRepaint(covariant SingleMarkerPainter oldDelegate) {
    if (oldDelegate.marker != marker) return true;
    return false;
  }
}
