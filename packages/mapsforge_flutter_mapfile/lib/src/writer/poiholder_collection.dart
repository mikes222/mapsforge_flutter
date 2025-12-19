import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tagholder_mixin.dart';

/// A helper class to hold all POIs for a specific zoom level during the
/// sub-file creation process.
class PoiholderCollection {
  Set<Poiholder> poiholders = {};

  Uint8List? content;

  int count = 0;

  PoiholderCollection();

  void addPoiholder(Poiholder poiholder) {
    assert(content == null);
    poiholders.add(poiholder);
    ++count;
  }

  void setPoidata(PointOfInterest poi) {
    assert(content == null);
    Poiholder poiholder = Poiholder(poi);
    poiholders.add(poiholder);
    ++count;
  }

  bool contains(PointOfInterest poi) {
    assert(content == null);
    return poiholders.firstWhereOrNull((test) => test.poi == poi) != null;
  }

  Uint8List writePoidata(bool debugFile, double tileLatitude, double tileLongitude) {
    if (content != null) return content!;
    Writebuffer writebuffer = Writebuffer();
    PoiholderWriter poiholderWriter = PoiholderWriter();
    for (Poiholder poiholder in poiholders) {
      poiholderWriter.writePoidata(writebuffer, poiholder, debugFile, tileLatitude, tileLongitude);
    }
    poiholders.clear();
    content = writebuffer.getUint8ListAndClear();
    return content!;
  }

  void createTagholders(List<Tagholder> tagsArray, List<String> languagesPreference) {
    for (Poiholder poiholder in poiholders) {
      poiholder.createTagholder(tagsArray, languagesPreference);
    }
  }
}
