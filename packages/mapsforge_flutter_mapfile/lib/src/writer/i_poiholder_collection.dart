import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

abstract class IPoiholderCollection {
  int get length;

  void add(Poiholder poiholder);

  void addAll(Iterable<Poiholder> poiholders);

  Future<Iterable<Poiholder>> getAll();

  Future<void> forEach(void Function(Poiholder poiholder) action);

  Future<void> removeWhere(bool Function(Poiholder poiholder) test);

  Future<void> mergeFrom(IPoiholderCollection other);

  Future<void> freeRessources();

  Future<void> dispose();
}
