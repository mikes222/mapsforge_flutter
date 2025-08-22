import 'package:dart_rendertheme/model.dart';

class LayerContainerCollection {
  static int MAX_DRAWING_LAYERS = 11;

  late final List<LayerContainer> drawingLayers;

  /// Potentially clashing renderinfos. These renderinfos will be removed if clashes with other objects of this collection occurs.
  final RenderInfoCollection _clashingInfoCollection = RenderInfoCollection([]);

  /// Potentially clashing AND rotating renderinfos. These infos will be removed if clashes occur and they will be rotated if the map rotates.
  final RenderInfoCollection _labels = RenderInfoCollection([]);

  LayerContainerCollection() {
    drawingLayers = List.generate(MAX_DRAWING_LAYERS, (int idx) => LayerContainer());
  }

  LayerContainer getLayer(int layer) {
    return drawingLayers.elementAt(layer);
  }

  /// The containers will be reduces to simplify the rendering.
  void reduce() {
    for (LayerContainer layerContainer in drawingLayers) {
      _clashingInfoCollection.renderInfos.addAll(layerContainer.clashingInfoCollection.renderInfos);
      layerContainer.clashingInfoCollection.clear();

      _labels.renderInfos.addAll(layerContainer.labels.renderInfos);
      layerContainer.labels.clear();
    }
    _clashingInfoCollection.collisionFreeOrdered();
    _labels.collisionFreeOrdered();
  }

  RenderInfoCollection get clashingInfoCollection => _clashingInfoCollection;

  RenderInfoCollection get labels => _labels;
}
