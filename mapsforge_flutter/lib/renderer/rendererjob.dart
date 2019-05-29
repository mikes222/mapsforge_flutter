import '../datastore/mapdatastore.dart';
import '../model/displaymodel.dart';
import '../model/tile.dart';
import '../queue/job.dart';
import '../rendertheme/rule/rendererthemefuture.dart';

class RendererJob extends Job {
  final DisplayModel displayModel;
  bool labelsOnly;
  final MapDataStore mapDataStore;
  final RenderThemeFuture renderThemeFuture;
  final double textScale;

  RendererJob(Tile tile, this.mapDataStore, this.renderThemeFuture,
      this.displayModel, this.textScale, bool isTransparent, bool labelsOnly)
      : super(tile, isTransparent) {
    if (mapDataStore == null) {
      throw new Exception("mapFile must not be null");
    } else if (textScale <= 0 || textScale == null) {
      throw new Exception("invalid textScale: $textScale");
    }

    this.labelsOnly = labelsOnly;
  }

  /**
   * Just a way of generating a hash key for a tile if only the RendererJob is known.
   *
   * @param tile the tile that changes
   * @return a RendererJob based on the current one, only tile changes
   */
  RendererJob otherTile(Tile tile) {
    return new RendererJob(tile, this.mapDataStore, this.renderThemeFuture,
        this.displayModel, this.textScale, this.hasAlpha, this.labelsOnly);
  }

  /**
   * Indicates that for this job only the labels should be generated.
   */
  void setRetrieveLabelsOnly() {
    this.labelsOnly = true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is RendererJob &&
          runtimeType == other.runtimeType &&
          displayModel == other.displayModel &&
          labelsOnly == other.labelsOnly &&
          mapDataStore == other.mapDataStore &&
          renderThemeFuture == other.renderThemeFuture &&
          textScale == other.textScale;

  @override
  int get hashCode =>
      super.hashCode ^
      displayModel.hashCode ^
      labelsOnly.hashCode ^
      mapDataStore.hashCode ^
      renderThemeFuture.hashCode ^
      textScale.hashCode;
}
