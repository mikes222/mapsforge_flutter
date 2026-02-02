import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/hgt_info.dart';
import 'package:mapsforge_flutter_renderer/src/ui/tile_picture.dart';

class HgtRenderer extends Renderer {
  static final _log = Logger('HgtRenderer');

  final IHgtFileProvider hgtFileProvider;

  late final HgtTileRenderer _tileColorRenderer;

  HgtRenderer({HgtTileRenderer? tileColorRenderer, int maxCachedFiles = 8, required this.hgtFileProvider})
    : _tileColorRenderer = tileColorRenderer ?? HgtTileColorRenderer();

  @override
  Future<JobResult> executeJob(JobRequest jobRequest) async {
    final Tile tile = jobRequest.tile;
    final tileSize = MapsforgeSettingsMgr().tileSize.ceil();
    final projection = PixelProjection(tile.zoomLevel);
    Mappoint leftUpper = tile.getLeftUpper();
    ILatLong leftUpperLL = projection.pixelToLatLong(leftUpper.x, leftUpper.y);
    HgtInfo hgtInfo = hgtFileProvider.getForLatLon(leftUpperLL.latitude, leftUpperLL.longitude, projection);

    final pixels = Uint8List(tileSize * tileSize * 4);

    for (int py = 0; py < tileSize;) {
      int nextPy = tileSize;
      for (int px = 0; px < tileSize;) {
        // examine each pixel of the tile
        ElevationArea? result = hgtFileProvider.elevationAround(hgtInfo, leftUpper, px, py);
        if (result == null) {
          // The file is missing
          // skip a few pixels to speed up
          px += 4;
          nextPy = py + 4;
          continue;
        }
        if (result.isOcean) {
          // The whole rectangle should be rendered as ocean
          for (int tileX = max(result.minTileX, 0); tileX <= min(result.maxTileX, tileSize - 1); ++tileX) {
            for (int tileY = max(result.minTileY, 0); tileY <= min(result.maxTileY, tileSize - 1); ++tileY) {
              _tileColorRenderer.render(pixels, tileSize, tileX, tileY, projection, leftUpperLL.latitude, leftUpperLL.longitude, ElevationArea.ocean);
            }
          }
          int nextPxCandidate = result.maxTileX + 1;
          if (nextPxCandidate <= px) nextPxCandidate = px + 1;
          px = nextPxCandidate;

          int nextPyCandidate = result.maxTileY + 1;
          if (nextPyCandidate <= py) nextPyCandidate = py + 1;
          if (nextPy > nextPyCandidate) nextPy = nextPyCandidate;
          continue;
        }
        //print("result: $result");
        // result gives us 4 locations of the tile with 4 elevations at each corner. Interpolate the elevations for this rectangle.
        //assert(result.minTileX >= px, "result.minTileX: ${result.minTileX}, px: $px");
        //assert(result.maxTileX < tileSize, "result.maxTileX: ${result.maxTileX}, tileSize: $tileSize");
        //assert(result.maxTileY < tileSize, "result.maxTileY: ${result.maxTileY}, tileSize: $tileSize");
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
    return 'hgt_${_tileColorRenderer.getRenderKey()}';
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

    final nx = tx.clamp(0.0, 1.0);
    final ny = ty.clamp(0.0, 1.0);

    if (area.hasOcean) {
      final oceanLT = area.leftTop == ElevationArea.ocean;
      final oceanRT = area.rightTop == ElevationArea.ocean;
      final oceanLB = area.leftBottom == ElevationArea.ocean;
      final oceanRB = area.rightBottom == ElevationArea.ocean;

      if (oceanLT) {
        if (nx + ny <= 1.0) return ElevationArea.ocean;
        final value = _interpolateTriangle(
          nx,
          ny,
          1.0,
          0.0,
          area.rightTop.toDouble(),
          0.0,
          1.0,
          area.leftBottom.toDouble(),
          1.0,
          1.0,
          area.rightBottom.toDouble(),
        );
        return value.round();
      }

      if (oceanRB) {
        if (nx + ny >= 1.0) return ElevationArea.ocean;
        final value = _interpolateTriangle(nx, ny, 0.0, 0.0, area.leftTop.toDouble(), 1.0, 0.0, area.rightTop.toDouble(), 0.0, 1.0, area.leftBottom.toDouble());
        return value.round();
      }

      if (oceanRT) {
        if (nx >= ny) return ElevationArea.ocean;
        final value = _interpolateTriangle(
          nx,
          ny,
          0.0,
          0.0,
          area.leftTop.toDouble(),
          0.0,
          1.0,
          area.leftBottom.toDouble(),
          1.0,
          1.0,
          area.rightBottom.toDouble(),
        );
        return value.round();
      }

      if (oceanLB) {
        if (nx <= ny) return ElevationArea.ocean;
        final value = _interpolateTriangle(
          nx,
          ny,
          0.0,
          0.0,
          area.leftTop.toDouble(),
          1.0,
          0.0,
          area.rightTop.toDouble(),
          1.0,
          1.0,
          area.rightBottom.toDouble(),
        );
        return value.round();
      }
    }

    final top = area.leftTop + (area.rightTop - area.leftTop) * nx;
    final bottom = area.leftBottom + (area.rightBottom - area.leftBottom) * nx;
    final value = top + (bottom - top) * ny;
    return value.round();
  }

  double _interpolateTriangle(double x, double y, double x1, double y1, double z1, double x2, double y2, double z2, double x3, double y3, double z3) {
    final denom = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3);
    if (denom == 0) return z1;
    final w1 = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denom;
    final w2 = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denom;
    final w3 = 1.0 - w1 - w2;
    return z1 * w1 + z2 * w2 + z3 * w3;
  }
}
