import 'dart:collection';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

/// A helper class to hold all POIs for a specific zoom level during the
/// sub-file creation process.
class PoiholderCollection implements IPoiholderCollection {
  final Queue<Poiholder> _entries = Queue();

  PoiholderCollection();

  @override
  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  @override
  void add(Poiholder poiholder) {
    _entries.add(poiholder);
  }

  @override
  void addAll(Iterable<Poiholder> poiholders) {
    _entries.addAll(poiholders);
  }

  void addPoidata(ILatLong latlong, TagholderCollection tagholderCollection) {
    Poiholder poiholder = Poiholder(position: latlong, tagholderCollection: tagholderCollection);
    _entries.add(poiholder);
  }

  @override
  Future<void> forEach(void Function(Poiholder poiholder) action) async {
    for (var poiholder in _entries) {
      action(poiholder);
    }
  }

  @override
  Future<void> removeWhere(bool Function(Poiholder poiholder) test) async {
    _entries.removeWhere(test);
  }

  @override
  Future<Iterable<Poiholder>> getAll() {
    return Future.value(_entries);
  }

  @override
  Future<void> dispose() async {
    _entries.clear();
  }

  @override
  Future<void> mergeFrom(IPoiholderCollection other) async {
    await other.forEach((action) {
      add(action);
    });
  }

  @override
  Future<void> freeRessources() async {}
}
