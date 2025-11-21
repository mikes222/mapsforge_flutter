import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/src/tile/tile_job_queue.dart';
import 'package:mapsforge_flutter/src/tile/tile_set.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';

class TilePainter extends CustomPainter {
  final TileJobQueue jobQueue;

  TilePainter(this.jobQueue) : super(repaint: jobQueue);

  @override
  void paint(Canvas canvas, Size size) {
    UiCanvas uiCanvas = UiCanvas(canvas, size);
    TileSet tileSet = jobQueue.tileSet!;
    Mappoint center = tileSet.getCenter();
    tileSet.images.forEach((Tile tile, TilePicture picture) {
      Mappoint leftUpper = tile.getLeftUpper();
      try {
        uiCanvas.drawTilePicture(picture: picture, left: leftUpper.x - center.x, top: leftUpper.y - center.y);
      } catch (error, stacktrace) {
        print(error);
        print(stacktrace);
        print(tile);
      }
    });
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) {
    if (oldDelegate.jobQueue.tileSet != jobQueue.tileSet) return true;
    return false;
  }
}
