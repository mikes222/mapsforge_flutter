import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';

class HgtTileColorRenderer implements HgtTileRenderer {
  final int minElevation;

  final int maxElevation;

  final int metersPerColorStep;

  final List<Color> colors;

  final Color oceanColor;

  late final int _lutSize;

  late final Uint32List _packedColorLut;

  late final int _packedOceanColor;

  /// Taken from http://soliton.vm.bytemark.co.uk/pub/cpt-city/grass/tn/elevation.png.index.html
  HgtTileColorRenderer({
    this.minElevation = 0,
    this.maxElevation = 2000,
    this.metersPerColorStep = 5,
    this.colors = const [
      Color.fromRGBO(0, 191, 191, 1),
      Color.fromRGBO(0, 255, 0, 1),
      Color.fromRGBO(255, 255, 0, 1),
      Color.fromRGBO(255, 127, 0, 1),
      Color.fromRGBO(191, 127, 63, 1),
      Color.fromRGBO(120, 120, 120, 1),
    ],
    this.oceanColor = const Color(0xffB3DDFF),
  }) : assert(metersPerColorStep > 0) {
    final span = (maxElevation - minElevation).clamp(0, 1 << 30);
    _lutSize = span ~/ metersPerColorStep + 1;
    _packedOceanColor = _packColor(oceanColor);
    _packedColorLut = _buildPackedColorLut();
  }

  @override
  void render(Uint8List pixels, int tileSize, int px, int py, PixelProjection projection, double latitude, double longitude, int elev) {
    final idx = py * tileSize + px;
    pixels.buffer.asUint32List()[idx] = _packedColorForElevation(elev);
  }

  void _setPixel(Uint8List rgba, int width, int x, int y, int r, int g, int b, int a) {
    assert(r >= 0 && r <= 255);
    assert(a >= 0 && a <= 255);
    final idx = y * width + x;
    rgba.buffer.asUint32List()[idx] = (a << 24) | (b << 16) | (g << 8) | r;
  }

  int _packedColorForElevation(int terrainAltitude) {
    if (maxElevation == 0) return 0;
    // -500 is ocean, see https://www.ngdc.noaa.gov/mgg/topo/report/s4/s4.html
    if (terrainAltitude == ElevationArea.ocean) return _packedOceanColor;

    final clamped = terrainAltitude.clamp(minElevation, maxElevation);
    final offset = clamped - minElevation;
    int i = offset ~/ metersPerColorStep;
    if (i < 0) i = 0;
    if (i >= _lutSize) i = _lutSize - 1;
    return _packedColorLut[i];
  }

  Uint32List _buildPackedColorLut() {
    final lut = Uint32List(_lutSize);
    for (int i = 0; i < _lutSize; i++) {
      final elev = minElevation + i * metersPerColorStep;
      final color = chooseColor(elev);
      lut[i] = _packColor(color);
    }
    return lut;
  }

  int _packColor(ui.Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final a = (color.a * 255).round();
    return (a << 24) | (b << 16) | (g << 8) | r;
  }

  ui.Color chooseColor(int terrainAltitude) {
    if (maxElevation == 0) return Colors.transparent;
    // -500 is ocean, see https://www.ngdc.noaa.gov/mgg/topo/report/s4/s4.html
    if (terrainAltitude == ElevationArea.ocean) return oceanColor;
    final normalized = (terrainAltitude - minElevation) / maxElevation;

    final scaled = normalized * (colors.length - 1);
    final lower = scaled.floor().clamp(0, colors.length - 1);
    final upper = (lower + 1).clamp(0, colors.length - 1);
    final t = (scaled - lower).clamp(0.0, 1.0);

    if (lower == upper) return colors[lower];
    return Color.lerp(colors[lower], colors[upper], t) ?? colors[lower];
  }

  @override
  String getRenderKey() {
    return 'color_${colors.hashCode}_${maxElevation}_$metersPerColorStep';
  }
}
