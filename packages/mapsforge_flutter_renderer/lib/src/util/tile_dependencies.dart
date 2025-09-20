import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

/// Tracks the dependencies between tiles for labels that cross tile boundaries.
///
/// When a label from one tile overlaps onto a neighboring tile, this class ensures
/// that the label is drawn correctly when the neighboring tile is rendered.
class TileDependencies {
  static final _log = Logger('TileDependencies');

  /// A map from a tile to the set of `RenderInfo` objects from other tiles
  /// that overlap with it.
  final Map<Tile, Dependency> _overlapData = {};

  TileDependencies();

  /// Clears all dependency data.
  void dispose() {
    _overlapData.forEach((tile, dependency) {
      dependency.clear();
    });
    _overlapData.clear();
  }

  /// Adds a `RenderInfo` that overlaps from its original tile onto the given [tile].
  void addOverlappingElement(RenderInfo renderInfo, Tile tile) {
    _overlapData.putIfAbsent(tile, () => Dependency()).add(renderInfo);
  }

  /// Returns true if the given [tile] has already been marked as drawn.
  bool isDrawn(Tile tile) {
    // Check cache first for frequently accessed tiles
    Dependency? dependency = _overlapData[tile];
    if (dependency != null) {
      return dependency.drawn;
    }
    return false;
  }

  /// Retrieves the set of `RenderInfo` objects that overlap with the given [tileToDraw].
  Set<RenderInfo>? getOverlappingElements(Tile tileToDraw) {
    return _overlapData[tileToDraw]?.renderInfos;
  }

  /// Marks a [tile] as drawn and clears its associated dependency data.
  void setDrawn(Tile tile) {
    Dependency? dependency = _overlapData[tile];
    if (dependency != null) {
      dependency.drawn = true;
      dependency.renderInfos.clear();
    }
  }

  /// Returns the set of neighboring tiles that have not yet been drawn.
  Set<Tile> getNeighbours(Tile tile) {
    Set<Tile> result = tile.getNeighbours();
    result.removeWhere((test) => isDrawn(test));
    return result;
  }

  @override
  String toString() {
    return 'TileDependencies{overlapData: $_overlapData}';
  }

  /// Logs the current state of the overlap data for debugging purposes.
  void debug() {
    _overlapData.forEach((key, innerMap) {
      _log.info("OverlapData: $key with $innerMap");
    });
  }
}

/////////////////////////////////////////////////////////////////////////////

/// A helper class to hold the dependency information for a single tile.
class Dependency {
  final Set<RenderInfo> renderInfos = {};

  bool drawn = false;

  Dependency();

  /// Adds a `RenderInfo` to this dependency.
  void add(RenderInfo renderInfo) {
    // is already rendered, makes no sense to store additional renderinfos
    if (drawn) return;
    renderInfos.add(renderInfo);
  }

  /// Clears the dependency information.
  void clear() {
    renderInfos.clear();
    drawn = false;
  }
}
