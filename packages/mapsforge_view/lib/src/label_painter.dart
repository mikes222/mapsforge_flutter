import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/src/label_set.dart';

class LabelPainter extends CustomPainter {
  final LabelSet labelSet;

  LabelPainter(this.labelSet);

  @override
  void paint(Canvas canvas, Size size) {
    UiCanvas uiCanvas = UiCanvas(canvas, size);
    Mappoint center = labelSet.getCenter();
    PixelProjection projection = labelSet.mapPosition.projection;
    UiRenderContext renderContext = UiRenderContext(
      canvas: uiCanvas,
      reference: center,
      projection: projection,
      rotationRadian: labelSet.mapPosition.rotationRadian,
    );
    for (var renderInfo in labelSet.renderInfos.renderInfos) {
      renderInfo.render(renderContext);
    }
  }

  @override
  bool shouldRepaint(covariant LabelPainter oldDelegate) {
    if (oldDelegate.labelSet != labelSet) return true;
    return false;
  }
}
