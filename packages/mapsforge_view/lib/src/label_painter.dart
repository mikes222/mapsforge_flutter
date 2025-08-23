import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/src/tile_set.dart';

class LabelPainter extends CustomPainter {
  final TileSet tileSet;

  LabelPainter(this.tileSet);

  @override
  void paint(Canvas canvas, Size size) {
    UiCanvas uiCanvas = UiCanvas(canvas, size);
    Mappoint center = tileSet.getCenter();
    tileSet.images.forEach((Tile tile, JobResult jobResult) {
      PixelProjection projection = PixelProjection(tile.zoomLevel);
      UiRenderContext renderContext = UiRenderContext(
        canvas: uiCanvas,
        reference: center,
        projection: projection,
        rotationRadian: tileSet.mapPosition.rotationRadian,
      );
      jobResult.renderInfo?.renderInfos.forEach((renderInfo) {
        renderInfo.render(renderContext);
      });
    });
  }

  @override
  bool shouldRepaint(covariant LabelPainter oldDelegate) {
    if (oldDelegate.tileSet != tileSet) return true;
    return false;
  }
}
