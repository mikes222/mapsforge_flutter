import 'dart:ui' as ui;

import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_text_paint.dart';

/// A singleton manager for caching `ui.Paragraph` objects.
///
/// This class improves text rendering performance by caching laid-out paragraphs.
/// It uses an LRU (Least Recently Used) strategy to manage the cache size and
/// ensures that `Paragraph` objects are properly disposed when evicted.
class ParagraphCacheMgr {
  static ParagraphCacheMgr? _instance;

  final LruCache<String, ParagraphEntry> _cache = LruCache<String, ParagraphEntry>(onEvict: (key, element) => element.dispose(), capacity: 2000);

  factory ParagraphCacheMgr() {
    if (_instance != null) return _instance!;
    _instance = ParagraphCacheMgr._();
    return _instance!;
  }

  ParagraphCacheMgr._();

  /// Retrieves or creates a cached [ParagraphEntry] for the given text and style.
  ///
  /// A unique key is generated from the text content and styling parameters.
  /// If an entry for this key exists in the cache, it is returned. Otherwise, a
  /// new [ParagraphEntry] is created, cached, and returned.
  ParagraphEntry getEntry(String text, UiTextPaint textPaint, UiPaint paint, double maxTextWidth) {
    String key =
        "$text-${textPaint.getFontFamily()}-${textPaint.getTextSize()}-${textPaint.getFontStyle().name}-${paint.getStrokeWidth()}-${paint.getColorAsNumber()}-$maxTextWidth";
    ParagraphEntry result = _cache.getOrProduceSync(key, (_) {
      return ParagraphEntry(text, paint, textPaint, maxTextWidth);
    });
    return result;
  }

  /// Clears the cache and disposes all cached paragraphs.
  void dispose() {
    _cache.dispose();
    _instance = null;
  }
}

/////////////////////////////////////////////////////////////////////////////

/// A wrapper around a `ui.Paragraph` object that represents a piece of
/// laid-out text.
///
/// This class handles the creation, layout, and disposal of the underlying
/// `Paragraph` object.
class ParagraphEntry {
  late ui.Paragraph paragraph;

  /// Creates a new [ParagraphEntry] by building and laying out a `ui.Paragraph`.
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

  /// Returns the width of the laid-out paragraph.
  double getWidth() {
    assert(paragraph.longestLine > 0, "Paragraph width is negative ${paragraph.longestLine}");
    return paragraph.longestLine;
  }

  /// Returns the height of the laid-out paragraph.
  double getHeight() {
    return paragraph.height;
  }

  /// Disposes the underlying `ui.Paragraph` to release its resources.
  void dispose() {
    paragraph.dispose();
  }
}
