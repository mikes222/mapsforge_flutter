import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/tile_color_renderer.dart';

class TileColorColorRenderer implements TileColorRenderer {
  final double maxElevation;

  final List<Color> colors;

  /// Taken from http://soliton.vm.bytemark.co.uk/pub/cpt-city/grass/tn/elevation.png.index.html
  TileColorColorRenderer({
    this.maxElevation = 2000,
    this.colors = const [
      Color.fromRGBO(0, 191, 191, 1),
      Color.fromRGBO(0, 255, 0, 1),
      Color.fromRGBO(255, 255, 0, 1),
      Color.fromRGBO(255, 127, 0, 1),
      Color.fromRGBO(191, 127, 63, 1),
      Color.fromRGBO(120, 120, 120, 1),
    ],
  });

  @override
  void render(Uint8List pixels, int tileSize, int px, int py, PixelProjection projection, double latitude, double longitude, int elev) {
    ui.Color color = chooseColor(elev.toDouble(), maxElevation);
    _setPixel(pixels, tileSize, px, py, (color.r * 255).round(), (color.g * 255).round(), (color.b * 255).round(), (color.a * 255).round());
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

  ui.Color chooseColor(double terrainAltitude, double referenceAltitude) {
    if (referenceAltitude == 0) return Colors.transparent;
    final normalized = terrainAltitude / referenceAltitude;
    if (normalized < 0) return Colors.transparent;

    final scaled = normalized * (colors.length - 1);
    final lower = scaled.floor().clamp(0, colors.length - 1);
    final upper = (lower + 1).clamp(0, colors.length - 1);
    final t = (scaled - lower).clamp(0.0, 1.0);

    if (lower == upper) return colors[lower];
    return Color.lerp(colors[lower], colors[upper], t) ?? colors[lower];
  }
}
