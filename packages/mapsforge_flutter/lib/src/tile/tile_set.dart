import 'package:datastore_renderer/ui.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter_core/model.dart';

class TileSet {
  final Mappoint center;

  final MapPosition mapPosition;

  final Map<Tile, TilePicture> images = {};

  TileSet({required this.center, required this.mapPosition});

  Mappoint getCenter() => center;
}
