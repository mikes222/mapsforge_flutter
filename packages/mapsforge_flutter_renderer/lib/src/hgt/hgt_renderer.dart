import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/elevation_color_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/hgt_file.dart';
import 'package:mapsforge_flutter_renderer/src/ui/tile_picture.dart';

enum HgtRenderMode { elevation, hillshade, color }

class HgtRenderer extends Renderer {
  static final _log = Logger('HgtRenderer');

  final IHgtFileProvider hgtFileProvider;
  final HgtRenderMode mode;

  /// Azimuth in degrees used for hillshade.
  final double hillshadeAzimuthDeg;

  /// Altitude in degrees used for hillshade.
  final double hillshadeAltitudeDeg;

  HgtRenderer({
    this.mode = HgtRenderMode.hillshade,
    int maxCachedFiles = 8,
    this.hillshadeAzimuthDeg = 315,
    this.hillshadeAltitudeDeg = 45,
    required this.hgtFileProvider,
  });

  @override
  Future<JobResult> executeJob(JobRequest jobRequest) async {
    final Tile tile = jobRequest.tile;
    final tileSize = MapsforgeSettingsMgr().tileSize.round();
    final projection = PixelProjection(tile.zoomLevel);
    final Mappoint leftUpper = tile.getLeftUpper();

    // Fast support check: does the tile center have an HGT file?
    final ILatLong centerLL = projection.pixelToLatLong(tile.getCenter().x, tile.getCenter().y);
    final HgtFile? centerFile = await hgtFileProvider.getForLatLon(centerLL.latitude, centerLL.longitude);
    if (centerFile == null) return JobResult.unsupported();

    final pixels = Uint8List(tileSize * tileSize * 4);

    int maxElevation = -10000;
    int minElevation = 10000;
    for (int py = 0; py < tileSize; py++) {
      for (int px = 0; px < tileSize; px++) {
        final worldX = leftUpper.x + px;
        final worldY = leftUpper.y + py;
        final ll = projection.pixelToLatLong(worldX, worldY);

        final elev = await _elevationAt(ll.latitude, ll.longitude);
        if (elev == null) {
          _setPixel(pixels, tileSize, px, py, 50, 0, 0, 10);
          continue;
        }
        if (maxElevation < elev) {
          maxElevation = elev;
        }
        if (minElevation > elev) {
          minElevation = elev;
        }

        switch (mode) {
          case HgtRenderMode.elevation:
            _elevationToGray(pixels, tileSize, px, py, elev);
            break;
          case HgtRenderMode.color:
            _elevationToColor(pixels, tileSize, px, py, elev);
            break;
          case HgtRenderMode.hillshade:
            await _hillshadeAt(pixels, tileSize, px, py, projection, ll.latitude, ll.longitude, elev);
            break;
        }
      }
    }

    final image = await _imageFromRgba(pixels, tileSize, tileSize);
    //_log.info("execute end job: ${jobRequest.tile} $minElevation - $maxElevation");
    return JobResult.normal(TilePicture.fromBitmap(image));
  }

  Future<int?> _elevationAt(double latitude, double longitude) async {
    final file = await hgtFileProvider.getForLatLon(latitude, longitude);
    if (file == null) return null;
    return file.elevationAt(latitude, longitude);
  }

  void _elevationToGray(Uint8List pixels, int tileSize, int px, int py, int meters) {
    // Clamp to typical SRTM range and map to [0..255].
    const minM = -500;
    const maxM = 5000;
    final clamped = meters.clamp(minM, maxM);
    final t = (clamped - minM) / (maxM - minM);
    final intensity = (t * 255).round().clamp(0, 255);
    _setPixel(pixels, tileSize, px, py, intensity, intensity, intensity, 255);
  }

  void _elevationToColor(Uint8List pixels, int tileSize, int px, int py, int meters) {
    ui.Color color = TerrainColorChooser().chooseColor(meters.toDouble(), 1000);
    _setPixel(pixels, tileSize, px, py, (color.r * 255).round(), (color.g * 255).round(), (color.b * 255).round(), (color.a * 255).round());
  }

  Future<void> _hillshadeAt(
    Uint8List pixels,
    int tileSize,
    int px,
    int py,
    PixelProjection projection,
    double latitude,
    double longitude,
    int centerElev,
  ) async {
    // Sample neighbours using a small geographic offset derived from meters-per-pixel.
    // This keeps the gradient scale stable across zoom levels.
    final mpp = projection.meterPerPixel(LatLong(latitude, longitude));
    if (mpp == 0) return;

    final dMeters = max(mpp, 1.0);
    final dLon = _metersToLongitudeDegrees(latitude, dMeters);
    final dLat = _metersToLatitudeDegrees(dMeters);

    final eW = await _elevationAt(latitude, longitude - dLon) ?? centerElev;
    final eE = await _elevationAt(latitude, longitude + dLon) ?? centerElev;
    final eN = await _elevationAt(latitude + dLat, longitude) ?? centerElev;
    final eS = await _elevationAt(latitude - dLat, longitude) ?? centerElev;

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

  Future<ui.Image> _imageFromRgba(Uint8List rgba, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, (img) {
      completer.complete(img);
    });
    return completer.future;
  }

  @override
  Future<JobResult> retrieveLabels(JobRequest jobRequest) {
    return Future.value(JobResult.unsupported());
  }

  @override
  String getRenderKey() {
    return 'hgt_${mode.name}_${hillshadeAzimuthDeg}_${hillshadeAltitudeDeg}';
  }

  @override
  bool supportLabels() {
    return false;
  }
}
