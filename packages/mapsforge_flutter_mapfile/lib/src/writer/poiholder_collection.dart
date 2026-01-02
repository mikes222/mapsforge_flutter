import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder_writer.dart';

/// A helper class to hold all POIs for a specific zoom level during the
/// sub-file creation process.
class PoiholderCollection implements IPoiholderCollection {
  final Set<Poiholder> _poiholders = {};

  PoiholderCollection();

  @override
  int get length => _poiholders.length;

  bool get isEmpty => _poiholders.isEmpty;

  @override
  void add(Poiholder poiholder) {
    _poiholders.add(poiholder);
  }

  @override
  void addAll(Iterable<Poiholder> poiholders) {
    _poiholders.addAll(poiholders);
  }

  void addPoidata(ILatLong latlong, TagholderCollection tagholderCollection) {
    Poiholder poiholder = Poiholder(position: latlong, tagholderCollection: tagholderCollection);
    _poiholders.add(poiholder);
  }

  @override
  Future<void> forEach(void Function(Poiholder poiholder) action) async {
    for (var poiholder in _poiholders) {
      action(poiholder);
    }
  }

  @override
  Future<void> removeWhere(bool Function(Poiholder poiholder) test) async {
    _poiholders.removeWhere(test);
  }

  @override
  Future<Iterable<Poiholder>> getAll() {
    return Future.value(_poiholders);
  }

  @override
  void writePoidata(Writebuffer writebuffer, bool debugFile, double tileLatitude, double tileLongitude, List<String> languagesPreferences) {
    PoiholderWriter poiholderWriter = PoiholderWriter();
    for (Poiholder poiholder in _poiholders) {
      poiholderWriter.writePoidata(writebuffer, poiholder, debugFile, tileLatitude, tileLongitude, languagesPreferences);
    }
  }

  @override
  Future<void> countTags(TagholderModel model) async {
    for (Poiholder poiholder in _poiholders) {
      poiholder.tagholderCollection.reconnectPoiTags(model);
      poiholder.tagholderCollection.countTags();
    }
  }

  @override
  void dispose() {
    _poiholders.clear();
  }
}
