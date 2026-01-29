import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/hgt_file.dart';
import 'package:mapsforge_flutter_renderer/src/ui/tile_picture.dart';

class HgtRenderer extends Renderer {
  static final _log = Logger('HgtRenderer');

  final IHgtFileProvider hgtFileProvider;

  late final TileColorRenderer _tileColorRenderer;

  HgtRenderer({TileColorRenderer? tileColorRenderer, int maxCachedFiles = 8, required this.hgtFileProvider})
    : _tileColorRenderer = tileColorRenderer ?? TileColorColorRenderer();

  @override
  Future<JobResult> executeJob(JobRequest jobRequest) async {
    final Tile tile = jobRequest.tile;
    final tileSize = MapsforgeSettingsMgr().tileSize.round();
    final projection = PixelProjection(tile.zoomLevel);
    final Mappoint leftUpper = tile.getLeftUpper();
    final leftUpperLL = projection.pixelToLatLong(leftUpper.x, leftUpper.y);
    final Mappoint rightLower = tile.getRightLower();
    final rightLowerLL = projection.pixelToLatLong(rightLower.x, rightLower.y);
    final file = hgtFileProvider.getForLatLon(leftUpperLL.latitude, leftUpperLL.longitude);

    final pixels = Uint8List(tileSize * tileSize * 4);

    for (int py = 0; py < tileSize;) {
      int nextPy = tileSize;
      for (int px = 0; px < tileSize;) {
        // examine each pixel of the tile
        //final elev = file.elevationAtTileXY(leftUpperLL, rightLowerLL, px, py, tileSize);
        final result = file.elevationAround(leftUpperLL, rightLowerLL, leftUpper, px, py, tileSize);
        if (result == null) {
          _setPixel(pixels, tileSize, px, py, 50, 0, 0, 10);
          ++px;
          continue;
        }
        // result gives us 4 locations of the tile with 4 elevations at each corner. Interpolate the elevations for this rectangle.
        //assert(result.minTileX >= px, "result.minTileX: ${result.minTileX}, px: $px");
        // assert(result.maxTileX < tileSize, "result.maxTileX: ${result.maxTileX}, tileSize: $tileSize");
        // assert(result.maxTileY < tileSize, "result.maxTileY: ${result.maxTileY}, tileSize: $tileSize");
        for (int tileX = max(result.minTileX, 0); tileX <= min(result.maxTileX, tileSize - 1); ++tileX) {
          for (int tileY = max(result.minTileY, 0); tileY <= min(result.maxTileY, tileSize - 1); ++tileY) {
            _tileColorRenderer.render(
              pixels,
              tileSize,
              tileX,
              tileY,
              projection,
              leftUpperLL.latitude,
              leftUpperLL.longitude,
              _interpolatedElevation(result, tileX, tileY),
            );
          }
        }
        int nextPxCandidate = result.maxTileX + 1;
        if (nextPxCandidate <= px) nextPxCandidate = px + 1;
        px = nextPxCandidate;

        int nextPyCandidate = result.maxTileY + 1;
        if (nextPyCandidate <= py) nextPyCandidate = py + 1;
        if (nextPy > nextPyCandidate) nextPy = nextPyCandidate;
      }

      if (nextPy <= py) nextPy = py + 1;
      py = nextPy;
    }

    final image = await _imageFromRgba(pixels, tileSize, tileSize);
    //_log.info("execute end job: ${jobRequest.tile} $minElevation - $maxElevation");
    return JobResult.normal(TilePicture.fromBitmap(image));
  }

  // int? _elevationAt(double latitude, double longitude) {
  //   //return file.elevationAt(latitude, longitude);
  // }

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
    return 'hgt';
  }

  @override
  bool supportLabels() {
    return false;
  }

  int _interpolatedElevation(ElevationArea area, int tileX, int tileY) {
    final dx = area.maxTileX - area.minTileX;
    final dy = area.maxTileY - area.minTileY;

    final tx = dx == 0 ? 0.0 : (tileX - area.minTileX) / dx;
    final ty = dy == 0 ? 0.0 : (tileY - area.minTileY) / dy;

    final top = area.leftTop + (area.rightTop - area.leftTop) * tx;
    final bottom = area.leftBottom + (area.rightBottom - area.leftBottom) * tx;
    final value = top + (bottom - top) * ty;
    return value.round();
  }
}
