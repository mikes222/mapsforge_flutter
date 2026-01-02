import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/wayholder_writer.dart';

/// A helper class to hold all ways for a specific zoom level during the
/// sub-file creation process.
class WayholderCollection implements IWayholderCollection {
  final Set<Wayholder> _wayholders = {};

  WayholderCollection();

  @override
  Future<int> nodeCount() async {
    int result = 0;
    for (var wayholder in _wayholders) {
      result += wayholder.nodeCount();
    }
    return result;
  }

  @override
  Future<int> pathCount() async {
    int result = 0;
    for (var wayholder in _wayholders) {
      result += wayholder.pathCount();
    }
    return result;
  }

  @override
  bool get isEmpty => _wayholders.isEmpty;

  @override
  int get length => _wayholders.length;

  @override
  Future<void> forEach(void Function(Wayholder wayholder) action) async {
    for (var wayholder in _wayholders) {
      action(wayholder);
    }
  }

  @override
  Future<void> removeWhere(bool Function(Wayholder wayholder) test) async {
    _wayholders.removeWhere(test);
  }

  @override
  Future<Iterable<Wayholder>> getAll() {
    return Future.value(_wayholders);
  }

  @override
  void add(Wayholder wayholder) {
    assert(wayholder.openOutersRead.isNotEmpty || wayholder.closedOutersRead.isNotEmpty);
    _wayholders.add(wayholder);
  }

  @override
  void addAll(Iterable<Wayholder> wayholders) {
    for (var test in wayholders) {
      assert(test.openOutersRead.isNotEmpty || test.closedOutersRead.isNotEmpty);
    }
    _wayholders.addAll(wayholders);
  }

  @override
  void writeWaydata(Writebuffer writebuffer, bool debugFile, Tile tile, double tileLatitude, double tileLongitude, List<String> languagesPreferences) {
    WayholderWriter wayholderWriter = WayholderWriter();
    for (Wayholder wayholder in _wayholders) {
      wayholderWriter.writeWaydata(writebuffer, wayholder, debugFile, tile, tileLatitude, tileLongitude, languagesPreferences);
    }
  }

  @override
  Future<void> countTags(TagholderModel model) async {
    for (Wayholder wayholder in _wayholders) {
      wayholder.tagholderCollection.reconnectWayTags(model);
      wayholder.tagholderCollection.countTags();
    }
  }

  @override
  Future<void> freeRessources() async {}

  @override
  Future<void> dispose() async {
    _wayholders.clear();
  }
}
