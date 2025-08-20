import 'dart:ui' as ui;

import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_text_paint.dart';
import 'package:ecache/ecache.dart';

class ParagraphCache {
  static ParagraphCache? _instance;

  final LruCache<String, ParagraphEntry> _cache = LruCache<String, ParagraphEntry>(storage: WeakReferenceStorage<String, ParagraphEntry>(), capacity: 1000);

  factory ParagraphCache() {
    if (_instance != null) return _instance!;
    _instance = ParagraphCache._();
    return _instance!;
  }

  ParagraphCache._();

  ParagraphEntry getEntry(String text, UiTextPaint textPaint, UiPaint paint, double maxTextWidth) {
    String key =
        "$text-${textPaint.getFontFamily()}-${textPaint.getTextSize()}-${textPaint.getFontStyle().name}-${paint.getStrokeWidth()}-${paint.getColorAsNumber()}-$maxTextWidth";
    ParagraphEntry result = _cache.getOrProduceSync(key, (_) {
      return ParagraphEntry(text, paint, textPaint, maxTextWidth);
    });
    return result;
  }
}

/////////////////////////////////////////////////////////////////////////////

class ParagraphEntry {
  late ui.Paragraph paragraph;

  ParagraphEntry(String text, UiPaint paint, UiTextPaint textPaint, double maxTextwidth) {
    ui.ParagraphBuilder builder = _buildParagraphBuilder(text, paint, textPaint);
    paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxTextwidth));
  }

  ui.ParagraphBuilder _buildParagraphBuilder(String text, UiPaint paint, UiTextPaint textPaint) {
    ui.ParagraphBuilder builder = textPaint.getParagraphBuilder(paint);
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
