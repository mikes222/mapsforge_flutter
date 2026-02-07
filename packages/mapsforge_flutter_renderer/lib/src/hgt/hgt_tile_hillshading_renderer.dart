import 'dart:math';
import 'dart:typed_data';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';

class HgtTileHillshadingRenderer implements HgtTileRenderer {
  /// Azimuth in degrees used for hillshade.
  final double hillshadeAzimuthDeg;

  /// Altitude in degrees used for hillshade.
  final double hillshadeAltitudeDeg;

  final HgtProvider hgtFileProvider;

  HgtTileHillshadingRenderer({this.hillshadeAzimuthDeg = 315, this.hillshadeAltitudeDeg = 45, required this.hgtFileProvider});

  @override
  void render(Uint8List pixels, int tileSize, int px, int py, PixelProjection projection, double latitude, double longitude, int centerElev) {
    // Sample neighbours using a small geographic offset derived from meters-per-pixel.
    // This keeps the gradient scale stable across zoom levels.
    final mpp = projection.meterPerPixel(LatLong(latitude, longitude));
    if (mpp == 0) return;

    final dMeters = max(mpp, 1.0);
    final dLon = _metersToLongitudeDegrees(latitude, dMeters);
    final dLat = _metersToLatitudeDegrees(dMeters);

    final eW = _elevationAt(latitude, longitude - dLon, projection) ?? centerElev;
    final eE = _elevationAt(latitude, longitude + dLon, projection) ?? centerElev;
    final eN = _elevationAt(latitude + dLat, longitude, projection) ?? centerElev;
    final eS = _elevationAt(latitude - dLat, longitude, projection) ?? centerElev;

    final dzdx = (eE - eW) / (2 * dMeters);
    final dzdy = (eN - eS) / (2 * dMeters);

    final az = hillshadeAzimuthDeg * pi / 180;
    final alt = hillshadeAltitudeDeg * pi / 180;

    // Surface normal.
    final nx = -dzdx;
    final ny = -dzdy;
    final nz = 1.0;
    final nLen = sqrt(nx * nx + ny * ny + nz * nz);

    final ux = cos(alt) * sin(az);
    final uy = cos(alt) * cos(az);
    final uz = sin(alt);

    final dot = (nx / nLen) * ux + (ny / nLen) * uy + (nz / nLen) * uz;
    final intensity = (dot.clamp(0.0, 1.0) * 255).round();
    _setPixel(pixels, tileSize, px, py, intensity, intensity, intensity, 255);
  }

  double _metersToLatitudeDegrees(double meters) {
    return meters / 111320.0;
  }

  double _metersToLongitudeDegrees(double latitude, double meters) {
    final latRad = latitude * pi / 180;
    final denom = 111320.0 * cos(latRad).abs();
    if (denom == 0) return 0;
    return meters / denom;
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

  int? _elevationAt(double latitude, double longitude, PixelProjection projection) {
    final file = hgtFileProvider.getForLatLon(latitude, longitude);
    return file.elevationAt(latitude, longitude);
  }

  @override
  String getRenderKey() {
    return 'hillshade';
  }
}
