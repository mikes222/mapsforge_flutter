import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/paintelements/point/mapelementcontainer.dart';

import '../model/tile.dart';

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
  final Map<Tile, Set<MapElementContainer>> overlapData = {};

  TileDependencies();

  /// stores an MapElementContainer that clashesWith from one tile (the one being drawn) to
  /// another (which must not have been drawn before).
  ///
  /// @param from    origin tile
  /// @param to      tile the label clashesWith to
  /// @param element the MapElementContainer in question
  bool addOverlappingElement(Tile neighbour, MapElementContainer element) {
    if (!overlapData.containsKey(neighbour)) {
      overlapData[neighbour] = {};
    } else {
      if (overlapData[neighbour]!.length == 0) {
        return true;
      }
    }
    overlapData[neighbour]!.add(element);
    return false;
  }

  void removeOverlappingElement(Tile neighbour, MapElementContainer element) {
    if (!overlapData.containsKey(neighbour)) return;
    overlapData[neighbour]!.remove(element);
  }

  /// Retrieves the overlap data from the neighbouring tiles and removes them from cache
  ///
  /// @param tileToDraw the tile which we want to draw now
  /// @param neighbour the tile the label clashesWith from. This is the originating tile where the label was not fully fit into
  /// @return a List of the elements
  Set<MapElementContainer>? getOverlappingElements(Tile tileToDraw) {
    Set<MapElementContainer>? map = overlapData[tileToDraw];
    if (map == null) return null;
    Set<MapElementContainer>? result = {};
    result.addAll(map);
    //map.remove(tileToDraw);
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
    return 'TileDependencies{overlapData: $overlapData}';
  }

  void debug() {
    overlapData.forEach((key, innerMap) {
      _log.info("OverlapData: $key with $innerMap");
    });
  }
}
