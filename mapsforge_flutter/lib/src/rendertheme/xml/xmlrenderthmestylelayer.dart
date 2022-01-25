/*
 * An individual layer in the rendertheme V4+ menu system.
 * A layer can have translations, categories that will always be enabled
 * when the layer is selected as well as optional overlays.
 */
class XmlRenderThemeStyleLayer {
  final Set<String> categories;
  final String defaultLanguage;
  final String id;
  final List<XmlRenderThemeStyleLayer> overlays;
  final Map<String, String> titles;
  final bool visible;
  final bool enabled;

  XmlRenderThemeStyleLayer(
      this.id, this.visible, this.enabled, this.defaultLanguage)
      : titles = new Map<String, String>(),
        categories = new Set(),
        overlays = [] {}

  void addCategory(String category) {
    this.categories.add(category);
  }

  void addOverlay(XmlRenderThemeStyleLayer overlay) {
    this.overlays.add(overlay);
  }

  void addTranslation(String language, String name) {
    this.titles[language] = name;
  }

  Set<String> getCategories() {
    return this.categories;
  }

  String getId() {
    return this.id;
  }

  List<XmlRenderThemeStyleLayer> getOverlays() {
    return this.overlays;
  }

  String? getTitle(String language) {
    String? result = this.titles[language];
    if (result == null) {
      return this.titles[this.defaultLanguage];
    }
    return result;
  }

  Map<String, String> getTitles() {
    return this.titles;
  }

  bool isEnabled() {
    return this.enabled;
  }

  bool isVisible() {
    return this.visible;
  }
}
