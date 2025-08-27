import 'dart:ui' as ui;

import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:datastore_renderer/src/ui/paragraph_cache.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';
import 'package:datastore_renderer/src/ui/tile_picture.dart';
import 'package:datastore_renderer/src/ui/ui_matrix.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_path.dart';
import 'package:datastore_renderer/src/ui/ui_rect.dart';
import 'package:datastore_renderer/src/ui/ui_text_paint.dart';
import 'package:flutter/cupertino.dart';

/// Canvas abstraction for cross-platform rendering operations.
/// 
/// This class provides a unified interface for drawing operations on Flutter's
/// canvas system, supporting both direct canvas rendering and picture recording
/// for cached tile generation. It includes performance tracking and optimized
/// drawing methods for map rendering.
/// 
/// Key features:
/// - Direct canvas and picture recorder support
/// - Performance metrics tracking (actions, bitmaps, text, paths)
/// - Optimized drawing methods for map elements
/// - Matrix transformations and clipping support
class UiCanvas {
  /// Underlying Flutter canvas for drawing operations.
  late ui.Canvas _uiCanvas;

  /// Picture recorder for generating cached tile images.
  ui.PictureRecorder? _pictureRecorder;

  /// The size of the canvas in logical pixels.
  final ui.Size _size;

  /// Counter for total drawing actions performed.
  int _actions = 0;

  /// Counter for bitmap drawing operations.
  int _bitmapCount = 0;

  /// Counter for text drawing operations.
  int _textCount = 0;

  /// Counter for path drawing operations.
  int _pathCount = 0;

  /// Creates a canvas wrapper for an existing Flutter canvas.
  /// 
  /// [_uiCanvas] Existing Flutter canvas to wrap
  /// [_size] Size of the canvas in logical pixels
  UiCanvas(this._uiCanvas, this._size) : _pictureRecorder = null;

  /// Creates a canvas with picture recording for cached tile generation.
  /// 
  /// This constructor creates a canvas that records drawing operations into
  /// a picture that can be cached and reused for improved performance.
  /// 
  /// [width] Width of the canvas in logical pixels
  /// [height] Height of the canvas in logical pixels
  UiCanvas.forRecorder(double width, double height)
    : _pictureRecorder = ui.PictureRecorder(),
      _size = ui.Size(width, height),
      assert(width >= 0),
      assert(height >= 0) {
    _uiCanvas = ui.Canvas(_pictureRecorder!);
  }

  /// Disposes of canvas resources and finalizes picture recording.
  /// 
  /// Should be called when the canvas is no longer needed to properly
  /// clean up resources and finalize any ongoing picture recording.
  void dispose() {
    _pictureRecorder?.endRecording();
  }

  /// Draws a Flutter icon using a TextPainter at the specified position.
  /// 
  /// [textPainter] Configured TextPainter with icon glyph
  /// [left] X coordinate for icon placement
  /// [top] Y coordinate for icon placement
  /// [matrix] Optional transformation matrix
  void drawIcon({required TextPainter textPainter, required double left, required double top, UiMatrix? matrix}) {
    if (matrix != null || left != 0 || top != 0) {
      _uiCanvas.save();
    }
    if (left != 0 || top != 0) {
      _uiCanvas.translate(left, top);
    }
    if (matrix != null) {
      _uiCanvas.transform(matrix.expose());
    }
    textPainter.paint(_uiCanvas, ui.Offset.zero);
    ++_bitmapCount;
    if (matrix != null || left != 0 || top != 0) {
      _uiCanvas.restore();
    }
  }

  void drawPicture({required SymbolImage symbolImage, required double left, required double top, required UiPaint paint, UiMatrix? matrix}) {
    if (matrix != null || left != 0 || top != 0) {
      _uiCanvas.save();
    }
    if (left != 0 || top != 0) {
      _uiCanvas.translate(left, top);
    }
    if (matrix != null) {
      _uiCanvas.transform(matrix.expose());
    }
    _uiCanvas.drawImage(symbolImage.expose(), ui.Offset.zero, paint.expose());
    ++_bitmapCount;
    if (matrix != null || left != 0 || top != 0) {
      _uiCanvas.restore();
    }
  }

  void drawTilePicture({required TilePicture picture, required double left, required double top}) {
    if (picture.getPicture() != null) {
      ui.Picture pic = picture.getPicture()!;
      _uiCanvas.save();
      _uiCanvas.translate(left, top);
      //double tileSize = MapsforgeConstants().tileSize;
      //_uiCanvas.clipRect(ui.Rect.fromLTWH(0, 0, tileSize, tileSize));
      _uiCanvas.drawPicture(pic);
      _uiCanvas.restore();
    } else {
      ui.Image image = picture.getImage()!; //await picture.convertPictureToImage()!;
      _uiCanvas.drawImage(image, ui.Offset(left, top), ui.Paint());
    }
    ++_bitmapCount;
  }

  void fillColorFromNumber(int color) {
    ui.Paint paint = ui.Paint()..color = ui.Color(color);
    _uiCanvas.drawRect(ui.Rect.fromLTWH(0, 0, _size.width, _size.height), paint);
    ++_actions;
  }

  void setClip(double left, double top, double width, double height) {
    _uiCanvas.clipRect(ui.Rect.fromLTWH(left, top, width, height), doAntiAlias: true);
  }

  /// Stops the recording and returns a TilePicture object.
  Future<TilePicture> finalizeBitmap() async {
    ui.Picture pic = _pictureRecorder!.endRecording();
    // unfortunately working with Picture is too slow because we have to render it each time
    ui.Image img = await pic.toImage(_size.width.ceil(), _size.height.ceil());
    _pictureRecorder = null;
    pic.dispose();
    TilePicture picture = TilePicture.fromBitmap(img);
    return picture;
  }

  void drawCircle(double x, double y, double radius, UiPaint paint) {
    //_log.info("draw circle at $x $y $radius $paint at ${ui.Offset(x.toDouble(), y.toDouble())}");
    _uiCanvas.drawCircle(ui.Offset(x, y), radius, paint.expose());
    ++_actions;
  }

  void drawLine(double x1, double y1, double x2, double y2, UiPaint paint) {
    //_log.info("draw line at $x1 $y1 $x2 $y2 $paint}");
    UiPath path = UiPath()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);

    drawPath(path, paint);
  }

  void drawPath(UiPath path, UiPaint paint) {
    path.drawPath(paint, _uiCanvas);
    ++_pathCount;
  }

  void drawRect(UiRect rect, UiPaint paint) {
    if (paint.getStrokeDasharray() != null && paint.getStrokeDasharray()!.length >= 2) {
      UiPath rectPath = UiPath();
      rectPath.addRect(rect);
      drawPath(rectPath, paint);
    } else {
      _uiCanvas.drawRect(rect.expose(), paint.expose());
      ++_actions;
    }
  }

  void drawPathText(String text, LineSegmentPath lineString, Mappoint reference, UiPaint paint, UiTextPaint textPaint, double maxTextWidth) {
    if (text.trim().isEmpty) {
      return;
    }
    if (paint.isTransparent()) {
      return;
    }

    ParagraphEntry entry = ParagraphCache().getEntry(text, textPaint, paint, maxTextWidth);

    for (var segment in lineString.segments) {
      // So text isn't upside down
      bool doInvert = segment.end.x < segment.start.x;
      RelativeMappoint start;
      double diff = (segment.length() - entry.getWidth()) / 2;
      if (doInvert) {
        //start = segment.end.offset(-origin.x, -origin.y);
        start = segment.pointAlongLineSegment(diff + entry.getWidth()).offset(reference);
      } else {
        //start = segment.start.offset(-origin.x, -origin.y);
        start = segment.pointAlongLineSegment(diff).offset(reference);
      }
      // print(
      //     "$text: segment length ${segment.length()} - word length ${entry.getWidth()} at ${start.x - segment.start.x} / ${start.y - segment.start.y} @ ${segment.getAngle()}");
      drawTextRotated(entry.paragraph, segment.getTheta(), start);
      //      len -= segmentLength;
    }
  }

  void drawTextRotated(ui.Paragraph paragraph, double theta, RelativeMappoint reference) {
    // since the text is rotated, use the textwidth as margin in all directions
    // if (start.x + textwidth < 0 ||
    //     start.y + textwidth < 0 ||
    //     start.x - textwidth > size.width ||
    //     start.y - textwidth > size.height) return;
    //double theta = segment.getTheta();

    // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas
    _uiCanvas.save();
    _uiCanvas.translate(
      /*translateX +*/
      reference.dx,
      /*translateY +*/ reference.dy,
    );
    _uiCanvas.rotate(theta);
    _uiCanvas.translate(0, -paragraph.height / 2);
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(0, 0, paragraph.longestLine, paragraph.height),
    //     ui.Paint()..color = Colors.red);
    // uiCanvas.drawCircle(Offset.zero, 10, ui.Paint()..color = Colors.green);
    _uiCanvas.drawParagraph(paragraph, ui.Offset.zero);
    _uiCanvas.restore();
    ++_textCount;
  }

  /// draws the given [text] so that the center of the text in at the given x/y coordinates
  void drawText(String text, double x, double y, UiPaint paint, UiTextPaint textPaint, double maxTextWidth) {
    ParagraphEntry entry = ParagraphCache().getEntry(text, textPaint, paint, maxTextWidth);
    double textwidth = entry.getWidth();
    double textHeight = entry.getHeight();
    if (x + textwidth / 2 < 0 || y + entry.getHeight() < 0 || x - textwidth / 2 > _size.width || y - entry.getHeight() > _size.height) return;
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(x - textwidth / 2, y - textHeight / 2,
    //         entry.getWidth(), entry.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.7));
    // uiCanvas.drawCircle(ui.Offset(x - textwidth / 2, y - textHeight / 2), 10,
    //     ui.Paint()..color = Colors.green);
    _uiCanvas.drawParagraph(entry.paragraph, ui.Offset(x - textwidth / 2, y - textHeight / 2));
    // uiCanvas.drawCircle(ui.Offset(x, y), 5, ui.Paint()..color = Colors.blue);
    ++_textCount;
  }

  void scale(ui.Offset focalPoint, double scale) {
    double diffX = _size.width / 2 - focalPoint.dx;
    double diffY = _size.height / 2 - focalPoint.dy;
    _uiCanvas.translate((-_size.width / 2 + diffX) * (scale - 1), (-_size.height / 2 + diffY) * (scale - 1));
    // This method scales starting from the top/left corner. That means that the top-left corner stays at its position and the rest is scaled.
    _uiCanvas.scale(scale);
  }

  void translate(double dx, double dy) {
    _uiCanvas.translate(dx, dy);
  }

  ui.Canvas expose() => _uiCanvas;

  @override
  String toString() {
    return 'FlutterCanvas{_actions: $_actions, _bitmapCount: $_bitmapCount, _textCount: $_textCount, _pathCount: $_pathCount}';
  }
}
