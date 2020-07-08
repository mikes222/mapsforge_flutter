import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

abstract class JobRenderer {
  Future<TileBitmap> executeJob(Job job);

  String getRenderKey();

  static final double margin = 5;

  Future<TileBitmap> createMissingBitmap(double tileSize) async {
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    paint.strokeWidth = 1;
    paint.color = ui.Color(0xffaaaaaa);
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset(margin, margin), ui.Offset(tileSize - margin, margin), paint);
    canvas.drawLine(ui.Offset(margin, margin), ui.Offset(margin, tileSize - margin), paint);
    canvas.drawLine(ui.Offset(tileSize - margin, margin), ui.Offset(tileSize - margin, tileSize - margin), paint);
    canvas.drawLine(ui.Offset(margin, tileSize - margin), ui.Offset(tileSize - margin, tileSize - margin), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 10.0, textAlign: TextAlign.center),
    )
      ..pushStyle(ui.TextStyle(color: paint.color))
      ..addText("Waiting for rendering...");
    canvas.drawParagraph(builder.build()..layout(ui.ParagraphConstraints(width: tileSize)), Offset(0, tileSize / 2));

    var pic = pictureRecorder.endRecording();
    ui.Image img = await pic.toImage(tileSize.toInt(), tileSize.toInt());
//    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//    var buffer = byteData.buffer.asUint8List();
    return FlutterTileBitmap(img);
  }

  Future<TileBitmap> createNoDataBitmap(double tileSize) async {
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    paint.strokeWidth = 1;
    paint.color = ui.Color(0xffaaaaaa);
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset(margin, margin), ui.Offset(tileSize - margin, margin), paint);
    canvas.drawLine(ui.Offset(margin, margin), ui.Offset(margin, tileSize - margin), paint);
    canvas.drawLine(ui.Offset(tileSize - margin, margin), ui.Offset(tileSize - margin, tileSize - margin), paint);
    canvas.drawLine(ui.Offset(margin, tileSize - margin), ui.Offset(tileSize - margin, tileSize - margin), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 14.0, textAlign: TextAlign.center),
    )
      ..pushStyle(ui.TextStyle(color: Colors.red))
      ..addText("No data available");
    canvas.drawParagraph(builder.build()..layout(ui.ParagraphConstraints(width: tileSize)), Offset(0, tileSize / 2));

    var pic = pictureRecorder.endRecording();
    ui.Image img = await pic.toImage(tileSize.toInt(), tileSize.toInt());
//    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//    var buffer = byteData.buffer.asUint8List();

    return FlutterTileBitmap(img);
  }

  Future<TileBitmap> createErrorBitmap(double tileSize, dynamic error) async {
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    paint.strokeWidth = 1;
    paint.color = ui.Color(0xffaaaaaa);
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset(margin, margin), ui.Offset(tileSize - margin, margin), paint);
    canvas.drawLine(ui.Offset(margin, margin), ui.Offset(margin, tileSize - margin), paint);
    canvas.drawLine(ui.Offset(tileSize - margin, margin), ui.Offset(tileSize - margin, tileSize - margin), paint);
    canvas.drawLine(ui.Offset(margin, tileSize - margin), ui.Offset(tileSize - margin, tileSize - margin), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 10.0, textAlign: TextAlign.center),
    )
      ..pushStyle(ui.TextStyle(color: Colors.black87))
      ..addText("${error?.toString() ?? "Error"}");
    canvas.drawParagraph(builder.build()..layout(ui.ParagraphConstraints(width: tileSize - margin * 2)), Offset(margin, margin));

    var pic = pictureRecorder.endRecording();
    ui.Image img = await pic.toImage(tileSize.toInt(), tileSize.toInt());
//    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//    var buffer = byteData.buffer.asUint8List();

    FlutterTileBitmap tileBitmap = FlutterTileBitmap(img);
    return tileBitmap; //Future.value(tileBitmap);
  }
}
