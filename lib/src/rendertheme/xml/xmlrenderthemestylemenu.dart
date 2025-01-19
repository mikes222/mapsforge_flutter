import 'package:mapsforge_flutter/src/rendertheme/xml/xmlrenderthmestylelayer.dart';

/**
 * Entry class for automatically building menus from rendertheme V4+ files.
 * This class holds all the defined layers and allows to retrieve them by name
 * or through iteration.
 * This class is Serializable to be able to pass an instance of it through the
 * Android Intent mechanism.
 */
class XmlRenderThemeStyleMenu {
  final Map<String, XmlRenderThemeStyleLayer> layers;
  final String defaultLanguage;
  final String defaultValue;
  final String id;

  XmlRenderThemeStyleMenu(this.id, this.defaultLanguage, this.defaultValue)
      : layers = new Map<String, XmlRenderThemeStyleLayer>();

  XmlRenderThemeStyleLayer createLayer(String id, bool visible, bool enabled) {
    XmlRenderThemeStyleLayer style = new XmlRenderThemeStyleLayer(
        id, visible, enabled, this.defaultLanguage);
    this.layers[id] = style;
    return style;
  }

  XmlRenderThemeStyleLayer? getLayer(String id) {
    return this.layers[id];
  }

  Map<String, XmlRenderThemeStyleLayer> getLayers() {
    return this.layers;
  }

  String getDefaultLanguage() {
    return this.defaultLanguage;
  }

  String getDefaultValue() {
    return this.defaultValue;
  }

  String getId() {
    return this.id;
  }
}
