import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

abstract class IWayholderCollection {
  int get length;

  bool get isEmpty;

  Future<void> countTags(TagholderModel model);

  Future<int> pathCount();

  Future<int> nodeCount();

  void add(Wayholder wayholder);

  void addAll(Iterable<Wayholder> wayholders);

  Future<void> forEach(void Function(Wayholder wayholder) action);

  Future<void> removeWhere(bool Function(Wayholder wayholder) test);

  Future<Iterable<Wayholder>> getAll();

  void writeWaydata(Writebuffer writebuffer, bool debugFile, Tile tile, double tileLatitude, double tileLongitude, List<String> languagesPreferences);

  /// Frees resources that cannot be transferred to an isolate.
  ///
  /// This is typically called before sending the `ReadbufferSource` to another isolate.
  Future<void> freeRessources();

  Future<void> dispose();
}
