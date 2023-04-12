import 'dart:ui' as ui;

import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';

class ParagraphCache {
  static ParagraphCache? _instance;

  LruCache<String, ParagraphEntry> _cache =
      new LruCache<String, ParagraphEntry>(
    storage: SimpleStorage<String, ParagraphEntry>(),
    capacity: 2000,
  );

  factory ParagraphCache() {
    if (_instance != null) return _instance!;
    _instance = ParagraphCache._();
    return _instance!;
  }

  ParagraphCache._();

  ParagraphEntry getEntry(String text, MapTextPaint mapTextPaint,
      MapPaint paint, double maxTextWidth) {
    String key =
        "$text-${mapTextPaint.getFontFamily()}-${mapTextPaint.getTextSize()}-${mapTextPaint.getFontStyle().name}-${paint.getStrokeWidth()}-$maxTextWidth";
    ParagraphEntry? result = _cache.get(key);
    if (result != null) return result;
    result = ParagraphEntry(text, paint, mapTextPaint, maxTextWidth);
    _cache[key] = result;
    return result;
  }
}

/////////////////////////////////////////////////////////////////////////////

class ParagraphEntry {
  late ui.Paragraph paragraph;

  ParagraphEntry(String text, MapPaint paint, MapTextPaint mapTextPaint,
      double maxTextwidth) {
    ui.ParagraphBuilder builder =
        _buildParagraphBuilder(text, paint, mapTextPaint);
    paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxTextwidth));
  }

  ui.ParagraphBuilder _buildParagraphBuilder(
      String text, MapPaint paint, MapTextPaint mapTextPaint) {
    String fontFamily = mapTextPaint
        .getFontFamily()
        .toString()
        .replaceAll("MapFontFamily.", "")
        .toLowerCase();

    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: mapTextPaint.getTextSize(),
        //textAlign: TextAlign.center,
        fontStyle: mapTextPaint.getFontStyle() == MapFontStyle.BOLD_ITALIC ||
                mapTextPaint.getFontStyle() == MapFontStyle.ITALIC
            ? ui.FontStyle.italic
            : ui.FontStyle.normal,
        fontWeight: mapTextPaint.getFontStyle() == MapFontStyle.BOLD ||
                mapTextPaint.getFontStyle() == MapFontStyle.BOLD_ITALIC
            ? ui.FontWeight.bold
            : ui.FontWeight.normal,
        fontFamily: fontFamily,
      ),
    );

    if (paint.getStrokeWidth() == 0)
      builder.pushStyle(ui.TextStyle(
        color: paint.getColor(),
        fontFamily: fontFamily,
      ));
    else
      builder.pushStyle(ui.TextStyle(
        foreground: ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = paint.getStrokeWidth()
          ..color = paint.getColor(),
        fontFamily: fontFamily,
      ));

    builder.addText(text);
    return builder;
  }

  double getWidth() {
    return paragraph.longestLine;
  }

  double getHeight() {
    return paragraph.height;
  }
}
