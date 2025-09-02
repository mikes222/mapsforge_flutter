import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/src/tile/tile_set.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';

class TilePainter extends CustomPainter {
  final TileSet tileSet;

  TilePainter(this.tileSet);

  @override
  void paint(Canvas canvas, Size size) {
    UiCanvas uiCanvas = UiCanvas(canvas, size);
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
    if (oldDelegate.tileSet != tileSet) return true;
    return false;
  }
}
