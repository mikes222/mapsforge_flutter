import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/renderer/shapecontainer.dart';

class Watercontainer implements ShapeContainer {
  Mappoint? center;
  List<List<Mappoint>>? coordinatesAbsolute;
  List<List<Mappoint>>? coordinatesRelativeToTile;
  final List<Tag> tags;
  final int layer;
  final Tile upperLeft;
  final bool isClosedWay;

  Watercontainer(List<Mappoint> coordinates, this.upperLeft, this.tags)
      : layer = 0,
        isClosedWay = coordinates[0] == (coordinates[coordinates.length - 1]) {
    this.coordinatesAbsolute = [];
    this.coordinatesRelativeToTile = null;
    this.coordinatesAbsolute!.add(List.from(coordinates));
  }
}
