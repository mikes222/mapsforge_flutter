import 'dart:ui' as ui;

import 'package:dart_common/utils.dart';
import 'package:datastore_renderer/src/model/tile_picture.dart';
import 'package:flutter/material.dart';

class ImageHelper {
  static final double _margin = 5;

  ///
  /// creates a tile bitmap with the information that the rendering of the given tile is not yet finished. This tile will normally
  /// be replaced
  /// when the rendering finishes.
  ///
  Future<TilePicture> createMissingBitmap() async {
    double tileSize = MapsforgeSettingsMgr().tileSize;
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    paint.strokeWidth = 1;
    paint.color = const ui.Color(0xffaaaaaa);
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset(_margin, _margin), ui.Offset(tileSize - _margin, _margin), paint);
    canvas.drawLine(ui.Offset(_margin, _margin), ui.Offset(_margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(tileSize - _margin, _margin), ui.Offset(tileSize - _margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(_margin, tileSize - _margin), ui.Offset(tileSize - _margin, tileSize - _margin), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 10.0, textAlign: ui.TextAlign.center))
      ..pushStyle(ui.TextStyle(color: paint.color))
      ..addText("Waiting for rendering...");
    canvas.drawParagraph(builder.build()..layout(ui.ParagraphConstraints(width: tileSize.toDouble())), ui.Offset(0, tileSize / 2));

    var pic = pictureRecorder.endRecording();
    return TilePicture.fromPicture(pic);
  }

  ///
  /// Creates a tilebitmap which denotes that there are no maps with any data found for the given tile.
  ///
  Future<TilePicture> createNoDataBitmap() async {
    double tileSize = MapsforgeSettingsMgr().tileSize;
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    paint.strokeWidth = 1;
    paint.color = const ui.Color(0xffaaaaaa);
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset(_margin, _margin), ui.Offset(tileSize - _margin, _margin), paint);
    canvas.drawLine(ui.Offset(_margin, _margin), ui.Offset(_margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(tileSize - _margin, _margin), ui.Offset(tileSize - _margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(_margin, tileSize - _margin), ui.Offset(tileSize - _margin, tileSize - _margin), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 14.0, textAlign: ui.TextAlign.center))
      ..pushStyle(ui.TextStyle(color: Colors.red))
      ..addText("No data available");
    canvas.drawParagraph(builder.build()..layout(ui.ParagraphConstraints(width: tileSize.toDouble())), ui.Offset(0, tileSize / 2));

    var pic = pictureRecorder.endRecording();
    //    ui.Image img = await pic.toImage(tileSize.toInt(), tileSize.toInt());
    return TilePicture.fromPicture(pic);
  }

  ///
  /// creates a bitmap tile with the given errormessage
  ///
  Future<TilePicture> createErrorBitmap(dynamic error) async {
    double tileSize = MapsforgeSettingsMgr().tileSize;
    var pictureRecorder = ui.PictureRecorder();
    var canvas = ui.Canvas(pictureRecorder);
    var paint = ui.Paint();
    paint.strokeWidth = 1;
    paint.color = const ui.Color(0xffaaaaaa);
    paint.isAntiAlias = true;

    canvas.drawLine(ui.Offset(_margin, _margin), ui.Offset(tileSize - _margin, _margin), paint);
    canvas.drawLine(ui.Offset(_margin, _margin), ui.Offset(_margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(tileSize - _margin, _margin), ui.Offset(tileSize - _margin, tileSize - _margin), paint);
    canvas.drawLine(ui.Offset(_margin, tileSize - _margin), ui.Offset(tileSize - _margin, tileSize - _margin), paint);

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 10.0, textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(color: Colors.black87))
      ..addText(error?.toString() ?? "Error");
    canvas.drawParagraph(builder.build()..layout(ui.ParagraphConstraints(width: tileSize - _margin * 2)), Offset(_margin, _margin));

    var pic = pictureRecorder.endRecording();
    return TilePicture.fromPicture(pic);
  }
}
