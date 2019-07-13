import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rendertheme.dart';

import '../datastore/mapdatastore.dart';
import '../model/displaymodel.dart';
import '../model/tile.dart';

class RendererJob extends Job {
//  final DisplayModel displayModel;
//  final bool labelsOnly;
//  final MapDataStore mapDataStore;
//  final RenderTheme renderTheme;
  final double textScale;

  RendererJob(
      Tile tile, /*this.mapDataStore, this.renderTheme, this.displayModel, */ this.textScale, bool isTransparent /*, this.labelsOnly*/)
      : //assert(mapDataStore != null),
        super(tile, isTransparent) {
    if (textScale <= 0 || textScale == null) {
      throw new Exception("invalid textScale: $textScale");
    }
  }

  /**
   * Just a way of generating a hash key for a tile if only the RendererJob is known.
   *
   * @param tile the tile that changes
   * @return a RendererJob based on the current one, only tile changes
   */
  RendererJob otherTile(Tile tile) {
    return new RendererJob(
        tile, /*this.mapDataStore, this.renderTheme, this.displayModel,*/ this.textScale, this.hasAlpha /*, this.labelsOnly*/);
  }

  /**
   * Indicates that for this job only the labels should be generated.
   */
//  void setRetrieveLabelsOnly() {
//    this.labelsOnly = true;
//  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is RendererJob &&
          runtimeType == other.runtimeType &&
//          displayModel == other.displayModel &&
//          labelsOnly == other.labelsOnly &&
//          mapDataStore == other.mapDataStore &&
//          renderTheme == other.renderTheme &&
          textScale == other.textScale;

//  @override
//  int get hashCode =>
//      super.hashCode ^ displayModel.hashCode ^ labelsOnly.hashCode ^ mapDataStore.hashCode ^ renderTheme.hashCode ^ textScale.hashCode;
}
