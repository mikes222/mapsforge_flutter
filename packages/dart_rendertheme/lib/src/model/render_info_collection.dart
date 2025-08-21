import 'package:dart_rendertheme/src/model/render_info.dart';

class RenderInfoCollection {
  final List<RenderInfo> renderInfos;

  RenderInfoCollection.empty() : renderInfos = [];

  RenderInfoCollection(this.renderInfos);

  void clear() {
    renderInfos.clear();
  }

  int get length => renderInfos.length;
}
