import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/renderer/jobrenderer.dart';

///
/// The dummy renderer renders dummy bitmaps for each given job
///
class DummyRenderer extends JobRenderer {
  @override
  Future<JobResult> executeJob(Job job) async {
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    Random random = Random();
    paint.strokeWidth = (random.nextDouble() * 5) + 1;
    paint.color = ui.Color(0xff000000 + random.nextInt(0xffffff));
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset.zero,
        ui.Offset(job.tileSize.toDouble(), job.tileSize.toDouble()), paint);
    canvas.drawLine(ui.Offset(job.tileSize.toDouble(), 0),
        ui.Offset(0, job.tileSize.toDouble()), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 10.0,
      ),
    )
      ..pushStyle(ui.TextStyle(color: Colors.black87))
      ..addText("${job.tile}");
    canvas.drawParagraph(
        builder.build()
          ..layout(ui.ParagraphConstraints(width: job.tileSize.toDouble())),
        const Offset(0, 0));

    var pic = pictureRecorder.endRecording();
    ui.Image img =
        await pic.toImage(job.tileSize.toInt(), job.tileSize.toInt());
//    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//    var buffer = byteData.buffer.asUint8List();

    FlutterTileBitmap tileBitmap = FlutterTileBitmap(img);
    return JobResult(tileBitmap, JOBRESULT.NORMAL); //Future.value(tileBitmap);
  }

  @override
  Future<JobResult> retrieveLabels(Job job) {
    throw UnimplementedError();
  }

  @override
  String getRenderKey() {
    return "dummy";
  }
}
