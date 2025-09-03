import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

abstract class DatastoreReader {
  Future<LayerContainerCollection?> read(Tile tile, RenderthemeZoomlevel renderthemeLevel);

  Future<LayerContainerCollection?> readLabels(Tile leftUpper, Tile rightLower, RenderthemeZoomlevel renderthemeLevel);
}
