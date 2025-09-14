import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

class FontWidthHelper {
  /// Calculates boundary with estimated text width based on actual text content.
  ///
  /// This method provides more accurate boundary calculations by estimating
  /// the actual text width using Flutter's TextPainter. Falls back to
  /// maxTextWidth if text is not available or measurement fails.
  ///
  /// [text] The text content to measure
  MapSize getBoundaryForText(String text, MapFontFamily fontFamily, MapFontStyle fontStyle, double fontSize, double strokeWidth, double maxTextLength) {
    if (text.isEmpty) return const MapSize.empty();

    // Average character width as fraction of font size
    // Monospace: ~0.6, Sans-serif: ~0.5, Serif: ~0.55
    double charWidthFactor = _getCharacterWidthFactor(fontFamily);

    // Account for font weight (bold text is wider)
    double weightMultiplier = fontStyle == MapFontStyle.BOLD || fontStyle == MapFontStyle.BOLD_ITALIC ? 1.1 : 1.0;

    // Add stroke padding if present
    double strokePadding = strokeWidth > 0 ? strokeWidth * 2 : 0;

    double width = text.length * fontSize * charWidthFactor * weightMultiplier + strokePadding * 2;

    int lines = (width / maxTextLength).ceil();
    if (lines > 1) {
      width = maxTextLength;
    }
    return MapSize(width: width, height: fontSize * lines);
  }

  /// Gets the font family name for TextStyle creation.
  // String _getFontFamilyName() {
  //   switch (fontFamily) {
  //     case MapFontFamily.DEFAULT:
  //       return 'Roboto';
  //     case MapFontFamily.MONOSPACE:
  //       return 'Courier New';
  //     case MapFontFamily.SANS_SERIF:
  //       return 'Arial';
  //     case MapFontFamily.SERIF:
  //       return 'Times New Roman';
  //   }
  // }

  /// Gets the FontStyle for TextStyle creation.
  // ui.FontStyle _getFontStyle() {
  //   switch (fontStyle) {
  //     case MapFontStyle.ITALIC:
  //     case MapFontStyle.BOLD_ITALIC:
  //       return ui.FontStyle.italic;
  //     default:
  //       return ui.FontStyle.normal;
  //   }
  // }

  /// Gets character width factor based on font family.
  double _getCharacterWidthFactor(MapFontFamily fontFamily) {
    switch (fontFamily) {
      case MapFontFamily.MONOSPACE:
        return 0.6; // Monospace characters are wider
      case MapFontFamily.SERIF:
        return 0.55; // Serif fonts are slightly wider
      case MapFontFamily.SANS_SERIF:
      case MapFontFamily.DEFAULT:
        return 0.5; // Sans-serif average
    }
  }
}
