import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';

class HgtTileGreyRenderer implements HgtTileRenderer {
  final Color oceanColor;

  HgtTileGreyRenderer({this.oceanColor = Colors.transparent});

  @override
  void render(Uint8List pixels, int tileSize, int px, int py, PixelProjection projection, double latitude, double longitude, int elev) {
    // -500 is ocean, see https://www.ngdc.noaa.gov/mgg/topo/report/s4/s4.html
    if (elev == HgtFile.ocean) {
      _setPixel(
        pixels,
        tileSize,
        px,
        py,
        (oceanColor.r * 255).round(),
        (oceanColor.g * 255).round(),
        (oceanColor.b * 255).round(),
        (oceanColor.a * 255).round(),
      );
      return;
    }

    // Clamp to typical SRTM range and map to [0..255].
    const minM = 0;
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
