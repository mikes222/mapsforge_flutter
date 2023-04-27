import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';

///
/// This abstract class provides the foundation to render a bitmap for the given tile.
///
abstract class JobRenderer {
  void dispose() {}

  ///
  /// The rendering job to execute.
  ///
  /// @returns the tilebitmap or null if no data available for this tile
  /// @returns an exception e.g. if the server is not reachable
  ///
  Future<JobResult> executeJob(Job job);

  /// For mapfiles we can either render everything into the images or render just the basic map and rotate the captions while rotating the map.
  /// If supported this method returns the captions to draw each time (maybe rotated)
  Future<JobResult> retrieveLabels(Job job);

  /// Returns a key for the caches. In order to use different caches for different renderings the
  /// renderer can provide a unique key. The key should be the same if the rendering should provide the
  /// exact same image again. The key should be different if the renderer provides different images. This
  /// can be used for light/dark themes.
  /// Note that different DisplayModels also may lead to different renderings (e.g. scaleFactors) but this
  /// is currently not implemented in the default renderers. We assume that the displaymodel stays the same
  /// at one single device or the cache will be deleted if the user changes the scalieFactors.
  String getRenderKey();

  static final double _margin = 5;

  ///
  /// creates a tile bitmap with the information that the rendering of the given tile is not yet finished. This tile will normally
  /// be replaced
  /// when the rendering finishes.
  ///
  Future<TileBitmap> createMissingBitmap(int tileSize) async {
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    paint.strokeWidth = 1;
    paint.color = const ui.Color(0xffaaaaaa);
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset(_margin, _margin),
        ui.Offset(tileSize - _margin, _margin), paint);
    canvas.drawLine(ui.Offset(_margin, _margin),
        ui.Offset(_margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(tileSize - _margin, _margin),
        ui.Offset(tileSize - _margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(_margin, tileSize - _margin),
        ui.Offset(tileSize - _margin, tileSize - _margin), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 10.0, textAlign: TextAlign.center),
    )
      ..pushStyle(ui.TextStyle(color: paint.color))
      ..addText("Waiting for rendering...");
    canvas.drawParagraph(
        builder.build()
          ..layout(ui.ParagraphConstraints(width: tileSize.toDouble())),
        Offset(0, tileSize / 2));

    var pic = pictureRecorder.endRecording();
    ui.Image img = await pic.toImage(tileSize.toInt(), tileSize.toInt());
//    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//    var buffer = byteData.buffer.asUint8List();
    return FlutterTileBitmap(img);
  }

  ///
  /// Creates a tilebitmap which denotes that there are no maps with any data found for the given tile.
  ///
  Future<TileBitmap> createNoDataBitmap(int tileSize) async {
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    paint.strokeWidth = 1;
    paint.color = const ui.Color(0xffaaaaaa);
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset(_margin, _margin),
        ui.Offset(tileSize - _margin, _margin), paint);
    canvas.drawLine(ui.Offset(_margin, _margin),
        ui.Offset(_margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(tileSize - _margin, _margin),
        ui.Offset(tileSize - _margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(_margin, tileSize - _margin),
        ui.Offset(tileSize - _margin, tileSize - _margin), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 14.0, textAlign: TextAlign.center),
    )
      ..pushStyle(ui.TextStyle(color: Colors.red))
      ..addText("No data available");
    canvas.drawParagraph(
        builder.build()
          ..layout(ui.ParagraphConstraints(width: tileSize.toDouble())),
        Offset(0, tileSize / 2));

    var pic = pictureRecorder.endRecording();
    ui.Image img = await pic.toImage(tileSize.toInt(), tileSize.toInt());
//    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//    var buffer = byteData.buffer.asUint8List();

    return FlutterTileBitmap(img);
  }

  ///
  /// creates a bitmap tile with the given errormessage
  ///
  Future<TileBitmap> createErrorBitmap(int tileSize, dynamic error) async {
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    paint.strokeWidth = 1;
    paint.color = const ui.Color(0xffaaaaaa);
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset(_margin, _margin),
        ui.Offset(tileSize - _margin, _margin), paint);
    canvas.drawLine(ui.Offset(_margin, _margin),
        ui.Offset(_margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(tileSize - _margin, _margin),
        ui.Offset(tileSize - _margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(_margin, tileSize - _margin),
        ui.Offset(tileSize - _margin, tileSize - _margin), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 10.0, textAlign: TextAlign.center),
    )
      ..pushStyle(ui.TextStyle(color: Colors.black87))
      ..addText("${error?.toString() ?? "Error"}");
    canvas.drawParagraph(
        builder.build()
          ..layout(ui.ParagraphConstraints(width: tileSize - _margin * 2)),
        Offset(_margin, _margin));

    var pic = pictureRecorder.endRecording();
    ui.Image img = await pic.toImage(tileSize, tileSize);
//    var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//    var buffer = byteData.buffer.asUint8List();

    FlutterTileBitmap tileBitmap = FlutterTileBitmap(img);
    return tileBitmap; //Future.value(tileBitmap);
  }
}
