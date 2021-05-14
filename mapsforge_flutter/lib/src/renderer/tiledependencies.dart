import '../mapelements/mapelementcontainer.dart';
import '../model/tile.dart';

/**
 * The TileDependecies class tracks the dependencies between tiles for labels.
 * When the labels are drawn on a per-tile basis it is important to know where
 * labels overlap the tile boundaries. A single label can overlap several neighbouring
 * tiles (even, as we do here, ignore the case where a long or tall label will overlap
 * onto tiles further removed -- with line breaks for long labels this should happen
 * much less frequently now.).
 * For every tile drawn we must therefore enquire which labels from neighbouring tiles
 * overlap onto it and these labels must be drawn regardless of priority as part of the
 * label has already been drawn.
 */
class TileDependencies {
  late Map<Tile, Map<Tile, Set<MapElementContainer>>> overlapData;

  // for the multithreaded renderer we also need to keep track of tiles that are in progress
  // and not yet in the TileCache to avoid truncated labels.
  late Set<Tile> tilesInProgress;

  TileDependencies() {
    overlapData = new Map<Tile, Map<Tile, Set<MapElementContainer>>>();
    tilesInProgress = new Set<Tile>();
  }

  /**
   * stores an MapElementContainer that clashesWith from one tile (the one being drawn) to
   * another (which must not have been drawn before).
   *
   * @param from    origin tile
   * @param to      tile the label clashesWith to
   * @param element the MapElementContainer in question
   */
  void addOverlappingElement(Tile from, Tile to, MapElementContainer element) {
    if (!overlapData.containsKey(from)) {
      overlapData[from] = new Map<Tile, Set<MapElementContainer>>();
    }
    if (!overlapData[from]!.containsKey(to)) {
      overlapData[from]![to] = new Set<MapElementContainer>();
    }
    overlapData[from]![to]!.add(element);
  }

  /**
   * Retrieves the overlap data from the neighbouring tiles
   *
   * @param from the origin tile
   * @param to   the tile the label clashesWith to
   * @return a List of the elements
   */
  Set<MapElementContainer>? getOverlappingElements(Tile from, Tile to) {
    if (overlapData.containsKey(from) && overlapData[from]!.containsKey(to)) {
      return overlapData[from]![to];
    }
    return new Set<MapElementContainer>();
  }

  /**
   * Cache maintenance operation to remove data for a tile from the cache. This should be excuted
   * if a tile is removed from the TileCache and will be drawn again.
   *
   * @param from
   */
  void removeTileData(Tile from, {Tile? to}) {
    if (to != null) {
      if (overlapData.containsKey(from)) {
        overlapData[from]!.remove(to);
      }
      return;
    }
    overlapData.remove(from);
  }

  bool isTileInProgress(Tile tile) {
    return tilesInProgress.contains(tile);
  }

  void addTileInProgress(Tile tileInProgress) {
    tilesInProgress.add(tileInProgress);
  }

  void removeTileInProgress(Tile tileFinished) {
    tilesInProgress.remove(tileFinished);
  }
}
