import 'package:dart_rendertheme/model.dart';

///
/// A container which holds all paintings for one layer. A layer is defined by the datastore. It is a property of the ways/pois
/// in the datastore. So in other words you can define which way should be drawn in the back and which should be drawn
/// at the front.
class LayerContainer {
  /// Default renderinfos
  final RenderInfoCollection renderInfoCollection = RenderInfoCollection([]);

  /// Potentially clashing renderinfos. These renderinfos will be removed if clashes with other objects of this collection occurs.
  final RenderInfoCollection _clashingInfoCollection = RenderInfoCollection([]);

  /// Potentially clashing AND rotating renderinfos. These infos will be removed if clashes occur and they will be rotated if the map rotates.
  final RenderInfoCollection _labels = RenderInfoCollection([]);

  ///
  /// Define the maximum number of levels.
  LayerContainer() {}

  void add(RenderInfo element) {
    renderInfoCollection.renderInfos.add(element);
  }

  void addLabel(RenderInfo element) {
    _labels.renderInfos.add(element);
  }

  void addClash(RenderInfo element) {
    _clashingInfoCollection.renderInfos.add(element);
  }

  // only for [LayerContainerCollection].reduce()
  RenderInfoCollection get clashingInfoCollection => _clashingInfoCollection;
  // only for [LayerContainerCollection].reduce()
  RenderInfoCollection get labels => _labels;
}
