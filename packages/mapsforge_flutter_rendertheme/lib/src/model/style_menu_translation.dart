/// Represents a localized `<name>` entry inside a Mapsforge RenderTheme
/// `<stylemenu>/<layer>`.
///
/// Documentation:
/// https://github.com/mapsforge/mapsforge/blob/master/docs/Rendertheme.md#stylemenus
class StyleMenuTranslation {
  /// Language code for the translation, e.g. `en`, `de`, `it`.
  ///
  /// XML: `<name lang="en" value="..."/>`
  final String lang;

  /// Translated display value.
  ///
  /// XML: `<name lang=".." value="..."/>`
  final String value;

  const StyleMenuTranslation({required this.lang, required this.value});
}
