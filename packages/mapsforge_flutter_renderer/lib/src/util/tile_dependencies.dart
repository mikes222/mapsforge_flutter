import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

/// The TileDependecies class tracks the dependencies between tiles for labels.
/// When the labels are drawn on a per-tile basis it is important to know where
/// labels overlap the tile boundaries. A single label can overlap several neighbouring
/// tiles (even, as we do here, ignore the case where a long or tall label will overlap
/// onto tiles further removed -- with line breaks for long labels this should happen
/// much less frequently now.).
/// For every tile drawn we must therefore enquire which labels from neighbouring tiles
/// overlap onto it and these labels must be drawn regardless of priority as part of the
/// label has already been drawn.
class TileDependencies {
  static final _log = Logger('TileDependencies');

  ///
  /// Data which the first tile (outer [Map]) has identified which should be drawn on the second tile (inner [Map]).
  /// Using a more efficient data structure for better performance
  final Map<Tile, Dependency> _overlapData = {};

  TileDependencies();

  void dispose() {
    _overlapData.forEach((tile, dependency) {
      dependency.clear();
    });
    _overlapData.clear();
  }

  /// stores an MapElementContainer that clashesWith from one tile (the one being drawn) to
  /// another (which must not have been drawn before).
  ///
  void addOverlappingElement(RenderInfo renderInfo, Tile tile) {
    _overlapData.putIfAbsent(tile, () => Dependency()).add(renderInfo);
  }

  /// Returns true if the given neighbour is already drawn
  bool isDrawn(Tile tile) {
    // Check cache first for frequently accessed tiles
    Dependency? dependency = _overlapData[tile];
    if (dependency != null) {
      return dependency.drawn;
    }
    return false;
  }

  /// Retrieves the overlap data from the neighbouring tiles and removes them from cache
  ///
  /// @param tileToDraw the tile which we want to draw now
  /// @param neighbour the tile the label clashesWith from. This is the originating tile where the label was not fully fit into
  /// @return a List of the elements
  Set<RenderInfo>? getOverlappingElements(Tile tileToDraw) {
    return _overlapData[tileToDraw]?.renderInfos;
  }

  void setDrawn(Tile tile) {
    Dependency? dependency = _overlapData[tile];
    if (dependency != null) {
      dependency.drawn = true;
      dependency.renderInfos.clear();
    }
  }

  Set<Tile> getNeighbours(Tile tile) {
    Set<Tile> result = tile.getNeighbours();
    result.removeWhere((test) => isDrawn(test));
    return result;
  }

  @override
  String toString() {
    return 'TileDependencies{overlapData: $_overlapData}';
  }

  void debug() {
    _overlapData.forEach((key, innerMap) {
      _log.info("OverlapData: $key with $innerMap");
    });
  }
}

/////////////////////////////////////////////////////////////////////////////

class Dependency {
  final Set<RenderInfo> renderInfos = {};

  bool drawn = false;

  Dependency();

  void add(RenderInfo renderInfo) {
    // is already rendered, makes no sense to store additional renderinfos
    if (drawn) return;
    renderInfos.add(renderInfo);
  }

  void clear() {
    renderInfos.clear();
    drawn = false;
  }
}
