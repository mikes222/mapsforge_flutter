import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/src/label/label_set.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

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
    for (RenderInfoCollection renderInfoCollection in labelSet.renderInfos) {
      for (var renderInfo in renderInfoCollection.renderInfos) {
        renderInfo.render(renderContext);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LabelPainter oldDelegate) {
    if (oldDelegate.labelSet != labelSet) return true;
    return false;
  }
}
