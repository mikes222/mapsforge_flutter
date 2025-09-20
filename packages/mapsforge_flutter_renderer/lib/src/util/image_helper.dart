import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/src/ui/tile_picture.dart';

/// A helper class for creating placeholder and error tile bitmaps.
class ImageHelper {
  static final double _margin = 5;

  /// todo since the images may be disposed by the receiving cache there may be a problem here. We should rather handle a clone() to the caller.
  static TilePicture? _missing;

  static TilePicture? _noData;

  /// Creates a tile bitmap to indicate that the tile is currently being rendered.
  ///
  /// This is used as a placeholder until the actual tile data is available.
  Future<TilePicture> createMissingBitmap() async {
    if (_missing != null) return _missing!.clone();
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
    _missing = TilePicture.fromPicture(pic);
    return _missing!;
  }

  /// Creates a tile bitmap to indicate that no map data is available for this tile.
  Future<TilePicture> createNoDataBitmap() async {
    if (_noData != null) return _noData!.clone();
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
    _noData = TilePicture.fromPicture(pic);
    return _noData!;
  }

  /// Creates a tile bitmap to display an error message.
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
