import 'dart:typed_data';

import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/hgt_tile_renderer.dart';

class HgtTileGreyRenderer implements HgtTileRenderer {
  HgtTileGreyRenderer();

  @override
  void render(Uint8List pixels, int tileSize, int px, int py, PixelProjection projection, double latitude, double longitude, int elev) {
    // Clamp to typical SRTM range and map to [0..255].
    const minM = -500;
    const maxM = 5000;
    final clamped = elev.clamp(minM, maxM);
    final t = (clamped - minM) / (maxM - minM);
    final intensity = (t * 255).round().clamp(0, 255);
    _setPixel(pixels, tileSize, px, py, intensity, intensity, intensity, 255);
  }

  void _setPixel(Uint8List rgba, int width, int x, int y, int r, int g, int b, int a) {
    assert(r >= 0 && r <= 255);
    assert(a >= 0 && a <= 255);
    final i = (y * width + x) * 4;
    rgba[i + 0] = r;
    rgba[i + 1] = g;
    rgba[i + 2] = b;
    rgba[i + 3] = a;
  }

  @override
  String getRenderKey() {
    return 'grey';
  }
}
