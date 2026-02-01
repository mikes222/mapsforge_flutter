import 'package:mapsforge_flutter_rendertheme/src/model/style_menu_layer.dart';

/// Model for Mapsforge RenderTheme `<stylemenu>`.
///
/// A `<stylemenu>` defines a set of layers (and their categories / overlays)
/// which can be toggled by the host application.
///
/// Documentation:
/// https://github.com/mapsforge/mapsforge/blob/master/docs/Rendertheme.md#stylemenus
class StyleMenu {
  /// The unique identifier of the style menu.
  ///
  /// XML: `<stylemenu id="...">`
  final String id;

  /// The default layer id to be selected.
  ///
  /// XML: `<stylemenu defaultvalue="...">`
  final String? defaultValue;

  /// The default language for localized layer names.
  ///
  /// XML: `<stylemenu defaultlang="...">`
  final String? defaultLang;

  /// All layer definitions contained in this menu.
  ///
  /// These are parsed from nested `<layer ...>` elements.
  final List<StyleMenuLayer> layers;

  const StyleMenu({required this.id, this.defaultValue, this.defaultLang, required this.layers});

  List<StyleMenuLayer> get visibleLayers {
    final visibleLayers = layers.where((l) => l.visible == true).toList(growable: false);
    if (visibleLayers.isNotEmpty) return visibleLayers;
    // if no layers are defined as visible treat all layers as visible
    return layers;
  }

  /// Returns the layer with the given [id], or null if it does not exist.
  StyleMenuLayer? layerById(String id) {
    for (final layer in layers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  Set<String> categoriesForLayer(StyleMenuLayer layer) {
    return categoriesForLayerId(layer.id);
  }

  Set<String> categoriesForLayerId(String layerId) {
    final result = <String>{};
    final visited = <String>{};
    _collectCategories(layerId, result, visited);
    return result;
  }

  void _collectCategories(String layerId, Set<String> result, Set<String> visited) {
    if (!visited.add(layerId)) return;

    final layer = layerById(layerId);
    if (layer == null) return;

    result.addAll(layer.categories);

    final parentId = layer.parent;
    if (parentId != null && parentId.isNotEmpty) {
      _collectCategories(parentId, result, visited);
    }

    for (final overlayId in layer.overlays) {
      if (overlayId.isEmpty) continue;
      _collectCategories(overlayId, result, visited);
    }
  }
}
