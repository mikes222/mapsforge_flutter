import 'package:dart_common/model.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/src/tile/tile_set.dart';

class TilePainter extends CustomPainter {
  final TileSet tileSet;

  TilePainter(this.tileSet);

  @override
  void paint(Canvas canvas, Size size) {
    UiCanvas uiCanvas = UiCanvas(canvas, size);
    Mappoint center = tileSet.getCenter();
    tileSet.images.forEach((Tile tile, TilePicture picture) {
      Mappoint leftUpper = tile.getLeftUpper();
      uiCanvas.drawTilePicture(picture: picture, left: leftUpper.x - center.x, top: leftUpper.y - center.y);
    });
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) {
    if (oldDelegate.tileSet != tileSet) return true;
    return false;
  }
}
