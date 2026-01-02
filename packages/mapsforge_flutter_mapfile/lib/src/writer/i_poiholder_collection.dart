import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

abstract class IPoiholderCollection {
  int get length;

  void add(Poiholder poiholder);

  void addAll(Iterable<Poiholder> poiholders);

  Future<Iterable<Poiholder>> getAll();

  Future<void> forEach(void Function(Poiholder poiholder) action);

  Future<void> removeWhere(bool Function(Poiholder poiholder) test);

  void writePoidata(Writebuffer writebuffer, bool debugFile, double tileLatitude, double tileLongitude, List<String> languagesPreferences);

  Future<void> countTags(TagholderModel model);

  void dispose();
}
