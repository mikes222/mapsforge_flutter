import 'dart:math';
import 'dart:ui' as ui;

import 'package:dart_common/utils.dart';
import 'package:datastore_renderer/src/job/job_request.dart';
import 'package:datastore_renderer/src/job/job_result.dart';
import 'package:datastore_renderer/src/ui/tile_picture.dart';
import 'package:datastore_renderer/src/renderer.dart';
import 'package:flutter/material.dart';

///
/// The dummy renderer renders dummy bitmaps for each given job
///
class DummyRenderer extends Renderer {
  @override
  Future<JobResult> executeJob(JobRequest job) async {
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    Random random = Random();
    double tileSize = MapsforgeSettingsMgr().tileSize;
    paint.strokeWidth = (random.nextDouble() * 5) + 1;
    paint.color = ui.Color(0xff000000 + random.nextInt(0xffffff));
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset.zero, ui.Offset(tileSize, tileSize), paint);
    canvas.drawLine(ui.Offset(tileSize, 0), ui.Offset(0, tileSize), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 10.0))
      ..pushStyle(ui.TextStyle(color: Colors.black87))
      ..addText("${job.tile}");
    canvas.drawParagraph(builder.build()..layout(ui.ParagraphConstraints(width: tileSize.toDouble())), const Offset(0, 0));

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
}
