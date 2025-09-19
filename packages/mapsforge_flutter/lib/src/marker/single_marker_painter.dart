import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/marker/marker.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';

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
