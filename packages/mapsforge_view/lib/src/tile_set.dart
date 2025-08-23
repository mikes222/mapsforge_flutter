import 'package:dart_common/model.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:mapsforge_view/mapsforge.dart';

class TileSet {
  final Mappoint center;

  final MapPosition mapPosition;

  final Map<Tile, JobResult> images = {};

  TileSet({required this.center, required this.mapPosition});

  Mappoint getCenter() => center;
}
