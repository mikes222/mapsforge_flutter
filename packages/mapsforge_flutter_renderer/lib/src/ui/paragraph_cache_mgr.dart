import 'dart:ui' as ui;

import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_text_paint.dart';

class ParagraphCacheMgr {
  static ParagraphCacheMgr? _instance;

  final LruCache<String, ParagraphEntry> _cache = LruCache<String, ParagraphEntry>(
    storage: WeakReferenceStorage<String, ParagraphEntry>(onEvict: (key, element) => element.dispose()),
    capacity: 1000,
  );

  factory ParagraphCacheMgr() {
    if (_instance != null) return _instance!;
    _instance = ParagraphCacheMgr._();
    return _instance!;
  }

  ParagraphCacheMgr._();

  ParagraphEntry getEntry(String text, UiTextPaint textPaint, UiPaint paint, double maxTextWidth) {
    String key =
        "$text-${textPaint.getFontFamily()}-${textPaint.getTextSize()}-${textPaint.getFontStyle().name}-${paint.getStrokeWidth()}-${paint.getColorAsNumber()}-$maxTextWidth";
    ParagraphEntry result = _cache.getOrProduceSync(key, (_) {
      return ParagraphEntry(text, paint, textPaint, maxTextWidth);
    });
    return result;
  }

  void dispose() {
    _cache.clear();
    _instance = null;
  }
}

/////////////////////////////////////////////////////////////////////////////

class ParagraphEntry {
  late ui.Paragraph paragraph;

  ParagraphEntry(String text, UiPaint paint, UiTextPaint textPaint, double maxTextwidth) {
    ui.ParagraphBuilder builder = _buildParagraphBuilder(text, paint, textPaint);
    paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxTextwidth));
    assert(paragraph.longestLine > 0, "Paragraph width is negative ${paragraph.longestLine} for text $text and maxTextwidth $maxTextwidth");
  }

  ui.ParagraphBuilder _buildParagraphBuilder(String text, UiPaint paint, UiTextPaint textPaint) {
    ui.ParagraphBuilder builder = textPaint.getParagraphBuilder(paint);
    builder.addText(text);
    return builder;
  }

  double getWidth() {
    assert(paragraph.longestLine > 0, "Paragraph width is negative ${paragraph.longestLine}");
    return paragraph.longestLine;
  }

  double getHeight() {
    return paragraph.height;
  }

  void dispose() {
    paragraph.dispose();
  }
}
