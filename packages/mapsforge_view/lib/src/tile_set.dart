import 'package:dart_common/model.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:mapsforge_view/mapsforge.dart';

class TileSet {
  final Mappoint center;

  final MapPosition mapPosition;

  final Map<Tile, TilePicture> images = {};

  TileSet({required this.center, required this.mapPosition});

  Mappoint getCenter() => center;
}
