import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/ui/tile_picture.dart';

///
/// The dummy renderer renders dummy bitmaps for each given job
///
class DummyRenderer extends Renderer {
  final int delayMilliseconds;

  DummyRenderer({this.delayMilliseconds = 0});

  @override
  Future<JobResult> executeJob(JobRequest job) async {
    if (delayMilliseconds > 0) {
      await Future.delayed(Duration(milliseconds: delayMilliseconds));
    }

    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    Random random = Random();
    double tileSize = MapsforgeSettingsMgr().tileSize;
    paint.strokeWidth = (random.nextDouble() * 5) + 1;
    paint.color = ui.Color(0xff000000 + random.nextInt(0xffffff));
    paint.isAntiAlias = true;
    paint.style = ui.PaintingStyle.stroke;
    double margin = 5;
    canvas.drawRect(Rect.fromLTWH(margin, margin, tileSize - margin * 2, tileSize - margin * 2), paint);
    canvas.drawCircle(Offset(tileSize / 2, tileSize / 2), 10, paint);

    ILatLong latLong = PixelProjection(job.tile.zoomLevel).pixelToLatLong(job.tile.getCenter().x, job.tile.getCenter().y);
    String text = "";
    text += "Tile/Pixel/LatLon\n";
    text += "${job.tile.tileX}/${job.tile.tileY}/${job.tile.zoomLevel} - ${job.tile.indoorLevel}\n";
    text += "${job.tile.getCenter().x.toStringAsFixed(0)}/${job.tile.getCenter().y.toStringAsFixed(0)}\n";
    text += "${latLong.latitude.toStringAsFixed(4)}/${latLong.longitude.toStringAsFixed(4)}";

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 22.0))
      ..pushStyle(ui.TextStyle(color: Colors.black87))
      ..addText(text);
    canvas.drawParagraph(
      builder.build()..layout(ui.ParagraphConstraints(width: tileSize.toDouble())),
      Offset((margin * 2 + paint.strokeWidth), margin * 2 + paint.strokeWidth),
    );

    var pic = pictureRecorder.endRecording();
    TilePicture tileBitmap = TilePicture.fromPicture(pic);
    return JobResult.normal(tileBitmap);
  }

  @override
  Future<JobResult> retrieveLabels(JobRequest job) {
    return Future.value(JobResult.unsupported());
  }

  @override
  String getRenderKey() {
    return "dummy";
  }

  @override
  bool supportLabels() {
    return false;
  }
}
