import 'package:logging/logging.dart';

import '../model/tile.dart';
import '../rendertheme/renderinfo.dart';

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
  static final _log = new Logger('TileDependencies');

  ///
  /// Data which the first tile (outer [Map]) has identified which should be drawn on the second tile (inner [Map]).
  final Map<Tile, Set<Dependency>> _overlapData = {};

  TileDependencies();

  void dispose() {
    _overlapData.forEach((tile, set) {
      set.forEach((dependency) {
        if (dependency.tiles.length > 0) {
          //dependency.element.dispose();
          dependency.tiles.clear();
        }
      });
    });
    _overlapData.clear();
  }

  /// stores an MapElementContainer that clashesWith from one tile (the one being drawn) to
  /// another (which must not have been drawn before).
  ///
  /// @param from    origin tile
  /// @param to      tile the label clashesWith to
  /// @param element the MapElementContainer in question
  void addOverlappingElement(RenderInfo element, List<Tile> tiles) {
    Dependency dependency = Dependency(element, tiles);
    tiles.forEach((tile) {
      if (!_overlapData.containsKey(tile)) {
        _overlapData[tile] = {};
      }
      _overlapData[tile]!.add(dependency);
    });
  }

  /// Returns true if the given neighbour is already drawn
  bool isDrawn(Tile neighbour) {
    if (!_overlapData.containsKey(neighbour)) return false;
    if (_overlapData[neighbour]!.length > 0) return false;
    return true;
  }

  /// If we want to draw an overlapping element and find out that this element
  /// overlaps to an neighbour which is already drawn (see [addOverlappingElement]
  /// We want to revert it and do not draw that element at all.
  // void removeOverlappingElement(Tile neighbour, MapElementContainer element) {
  //   if (_overlapData[neighbour] == null) return;
  //   if (_overlapData[neighbour]!.length > 0) {
  //     _overlapData[neighbour]?.remove(element);
  //     if (_overlapData[neighbour]!.length == 0) {
  //       // we removed the last element, remove the key so that we treat the neighbour as "not yet seen"
  //       _overlapData.remove(neighbour);
  //     }
  //   }
  // }

  /// Retrieves the overlap data from the neighbouring tiles and removes them from cache
  ///
  /// @param tileToDraw the tile which we want to draw now
  /// @param neighbour the tile the label clashesWith from. This is the originating tile where the label was not fully fit into
  /// @return a List of the elements
  Set<Dependency>? getOverlappingElements(Tile tileToDraw) {
    Set<Dependency>? map = _overlapData[tileToDraw];
    if (map == null) {
      // we do not have anything for this tile but mark it as "drawn" now
      _overlapData[tileToDraw] = {};
      return null;
    }

    /// hmm, sometimes the map is empty, I do not understand why
    //assert(map.length > 0);
    Set<Dependency> result = {};
    map.forEach((dependency) {
      bool removed = dependency.tiles.remove(tileToDraw);
      assert(removed);
      result.add(dependency);
    });
    // mark as drawn
    map.clear();
    return result;
  }

  /**
   * Cache maintenance operation to remove data for a tile from the cache. This should be excuted
   * if a tile is removed from the TileCache and will be drawn again.
   *
   * @param from
   */
  // void removeTileData(Tile from, {Tile? to}) {
  //   if (to != null) {
  //     if (overlapData.containsKey(from)) {
  //       overlapData[from]!.remove(to);
  //     }
  //     return;
  //   }
  //   overlapData.remove(from);
  // }

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
  final RenderInfo element;

  List<Tile> tiles;

  Dependency(this.element, this.tiles);
}
