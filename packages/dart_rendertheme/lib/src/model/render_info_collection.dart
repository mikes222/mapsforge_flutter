import 'package:dart_rendertheme/src/model/render_info.dart';

class RenderInfoCollection {
  final List<RenderInfo> renderInfos;

  RenderInfoCollection.empty() : renderInfos = [];

  RenderInfoCollection(this.renderInfos);

  void clear() {
    renderInfos.clear();
  }

  int get length => renderInfos.length;

  /// Transforms a list of MapElements, orders it and removes those elements that overlap.
  /// This operation is useful for an early elimination of elements in a list that will never
  /// be drawn because they overlap. Overlapping items will be disposed.
  ///
  /// @param input list of MapElements
  /// @return collision-free, ordered list, a subset of the input.
  void collisionFreeOrdered() {
    // sort items by priority (highest first)
    //    renderInfos.sort((a, b) => b.renderInstruction.priority.compareTo(a.renderInstruction.priority));
    // in order of priority, see if an item can be drawn, i.e. none of the items
    // in the currentItemsToDraw list clashes with it.
    List<RenderInfo> output = [];
    for (RenderInfo item in renderInfos) {
      if (haveSpace(item, output)) {
        output.add(item);
      } else {
        //item.dispose();
      }
    }
    renderInfos.clear();
    renderInfos.addAll(output);
  }

  bool haveSpace(RenderInfo item, List<RenderInfo> list) {
    for (RenderInfo outputElement in list) {
      //      try {
      if (outputElement.clashesWith(item)) {
        //print("$outputElement --------clashesWith-------- $item");
        return false;
      }
      // } catch (error) {
      //   // seems we cannot find out if we clash, so just use it for now
      //   return true;
      // }
    }
    return true;
  }
}
