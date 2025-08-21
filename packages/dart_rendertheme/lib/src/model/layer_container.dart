import 'package:dart_rendertheme/src/model/render_info.dart';
import 'package:dart_rendertheme/src/model/render_info_collection.dart';

///
/// A container which holds all paintings for one layer. A layer is defined by the datastore. It is a property of the ways/pois
/// in the datastore. So in other words you can define which way should be drawn in the back and which should be drawn
/// at the front.
class LayerContainer {
  static int MAX_DRAWING_LAYERS = 11;

  late RenderInfoCollection renderInfoCollection = RenderInfoCollection([]);

  late RenderInfoCollection clashingInfoCollection = RenderInfoCollection([]);

  late RenderInfoCollection labels = RenderInfoCollection([]);

  ///
  /// Define the maximum number of levels.
  LayerContainer() {}

  void add(RenderInfo element) {
    renderInfoCollection.renderInfos.add(element);
  }

  void addLabel(RenderInfo element) {
    labels.renderInfos.add(element);
  }

  void addClash(RenderInfo element) {
    clashingInfoCollection.renderInfos.add(element);
  }
}
