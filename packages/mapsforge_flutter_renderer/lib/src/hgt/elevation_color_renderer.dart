import 'package:flutter/material.dart';

class ElevationColorRenderer {}

/// Taken from http://soliton.vm.bytemark.co.uk/pub/cpt-city/grass/tn/elevation.png.index.html
class TerrainColorChooser {
  final List<Color> _colors = [
    const Color.fromRGBO(0, 191, 191, 1),
    const Color.fromRGBO(0, 255, 0, 1),
    const Color.fromRGBO(255, 255, 0, 1),
    const Color.fromRGBO(255, 127, 0, 1),
    const Color.fromRGBO(191, 127, 63, 1),
    const Color.fromRGBO(120, 120, 120, 1),
  ];

  Color chooseColor(double terrainAltitude, double referenceAltitude) {
    if (referenceAltitude == 0) return Colors.transparent;
    final normalized = terrainAltitude / referenceAltitude;
    if (normalized < 0) return Colors.transparent;

    final scaled = normalized * (_colors.length - 1);
    final lower = scaled.floor().clamp(0, _colors.length - 1);
    final upper = (lower + 1).clamp(0, _colors.length - 1);
    final t = (scaled - lower).clamp(0.0, 1.0);

    if (lower == upper) return _colors[lower];
    return Color.lerp(_colors[lower], _colors[upper], t) ?? _colors[lower];
  }
}
