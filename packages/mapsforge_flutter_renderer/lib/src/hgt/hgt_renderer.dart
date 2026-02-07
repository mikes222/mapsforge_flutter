import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/ui/tile_picture.dart';

class HgtRenderer extends Renderer {
  static final _log = Logger('HgtRenderer');

  final HgtProvider hgtProvider;

  late final HgtTileRenderer _tileColorRenderer;

  HgtRenderer({HgtTileRenderer? tileColorRenderer, int maxCachedFiles = 8, required this.hgtProvider})
    : _tileColorRenderer = tileColorRenderer ?? HgtTileColorRenderer();

  @override
  Future<JobResult> executeJob(JobRequest jobRequest) async {
    final Tile tile = jobRequest.tile;
    final tileSize = MapsforgeSettingsMgr().tileSize.ceil();
    final projection = PixelProjection(tile.zoomLevel);
    Mappoint leftUpper = tile.getLeftUpper();
    HgtInfo hgtInfo = HgtInfo(projection: projection, hgtProvider: hgtProvider);

    final pixels = Uint8List(tileSize * tileSize * 4);

    hgtInfo.render(leftUpper: leftUpper, tileSize: tileSize, tileRenderer: _tileColorRenderer, pixels: pixels);

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
}
