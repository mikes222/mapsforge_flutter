import 'package:mapsforge_flutter_rendertheme/src/model/style_menu_translation.dart';

/// Represents a `<layer>` element inside a Mapsforge RenderTheme `<stylemenu>`.
///
/// A layer groups multiple categories (`<cat id="..."/>`) and/or overlay layers
/// (`<overlay id="..."/>`) to be toggled together.
///
/// Documentation:
/// https://github.com/mapsforge/mapsforge/blob/master/docs/Rendertheme.md#stylemenus
class StyleMenuLayer {
  /// Unique layer identifier.
  ///
  /// XML: `<layer id="...">`
  final String id;

  /// Whether this layer should be enabled by default.
  ///
  /// XML: `<layer enabled="true|false">`
  ///
  /// If this attribute is not present, this value is `null`.
  final bool? enabled;

  /// Whether this layer should be visible to the user (i.e. shown in a UI).
  ///
  /// XML: `<layer visible="true|false">`
  ///
  /// Mapsforge uses `visible="true"` for user-selectable styles and
  /// `visible="false"` for internal/base layers.
  ///
  /// If this attribute is not present, this value is `null`.
  final bool? visible;

  /// Optional parent layer id.
  ///
  /// XML: `<layer parent="base">`
  final String? parent;

  /// Localized names of this layer.
  ///
  /// XML: `<name lang=".." value=".."/>`
  final List<StyleMenuTranslation> names;

  /// Category ids controlled by this layer.
  ///
  /// XML: `<cat id="..."/>`
  ///
  /// These ids refer to `<rule cat="...">` categories.
  final List<String> categories;

  /// Overlay layer ids referenced by this layer.
  ///
  /// XML: `<overlay id="..."/>`
  final List<String> overlays;

  StyleMenuLayer({required this.id, this.enabled, this.visible, this.parent, required this.names, required this.categories, required this.overlays})
    : assert(names.isNotEmpty);

  /// Returns the best matching localized name.
  ///
  /// Fallback order:
  /// - exact match for [lang]
  /// - exact match for [fallbackLang] (if provided)
  /// - first entry in [names]
  /// - `null` if no translations exist
  String? nameForLang(String lang, {String? fallbackLang}) {
    for (final t in names) {
      if (t.lang == lang) return t.value;
    }
    if (fallbackLang != null) {
      for (final t in names) {
        if (t.lang == fallbackLang) return t.value;
      }
    }
    return names.first.value;
  }
}
