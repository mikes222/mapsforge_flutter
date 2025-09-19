import 'package:mapsforge_flutter_rendertheme/model.dart';

/// A collection of layers. The id of the layer is defined by the node/way property in the mapfile. Since only 4 bits are reserved the layer can be max. 0-15.
class LayerContainerCollection {
  static int MAX_DRAWING_LAYERS = 11;

  late final List<LayerContainer> _drawingLayers;

  final RenderInfoCollection _drawings = RenderInfoCollection([]);

  /// Potentially clashing renderinfos. These renderinfos will be removed if clashes with other objects of this collection occurs.
  final RenderInfoCollection _clashingInfoCollection = RenderInfoCollection([]);

  /// Potentially clashing AND rotating renderinfos. These infos will be removed if clashes occur and they will be rotated if the map rotates.
  final RenderInfoCollection _labels = RenderInfoCollection([]);

  LayerContainerCollection(int maxLevels) {
    _drawingLayers = List.generate(MAX_DRAWING_LAYERS, (int idx) => LayerContainer(maxLevels));
  }

  LayerContainer getLayer(int layer) {
    return _drawingLayers.elementAt(layer);
  }

  /// The containers will be reduces to simplify the rendering.
  void reduce() {
    for (LayerContainer layerContainer in _drawingLayers) {
      for (RenderInfoCollection renderInfoCollection in layerContainer.levels) {
        _drawings.renderInfos.addAll(renderInfoCollection.renderInfos);
        renderInfoCollection.clear();
      }

      _clashingInfoCollection.renderInfos.addAll(layerContainer.clashingInfoCollection.renderInfos);
      layerContainer.clashingInfoCollection.clear();

      _labels.renderInfos.addAll(layerContainer.labels.renderInfos);
      layerContainer.labels.clear();
    }
    _drawingLayers.clear();
  }

  RenderInfoCollection get clashingInfoCollection => _clashingInfoCollection;

  RenderInfoCollection get labels => _labels;

  RenderInfoCollection get drawings => _drawings;
}
