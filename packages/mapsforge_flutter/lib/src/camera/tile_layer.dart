import 'dart:ui';

import 'package:mapsforge_flutter/src/camera/map_camera.dart';
import 'package:mapsforge_flutter/src/camera/map_layer.dart';
import 'package:mapsforge_flutter/src/camera/tile_engine.dart';
import 'package:mapsforge_flutter/src/tile/tile_painter.dart';

class TileLayer extends MapLayer {
  final TileEngine tiles;
  TileLayer(this.tiles);

  @override
  void attach({required MapCamera camera}) {
    super.attach(camera: camera);
    tiles.addListener(notifyListeners); // bubble engine updates → scene repaint
  }

  @override
  void dispose() {
    tiles.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ts = tiles.tiles;
    if (ts == null) return;
    TilePainter(ts).paint(canvas, size);
  }
}
