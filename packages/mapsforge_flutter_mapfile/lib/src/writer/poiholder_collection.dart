import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder_writer.dart';

/// A helper class to hold all POIs for a specific zoom level during the
/// sub-file creation process.
class PoiholderCollection {
  Set<Poiholder> poiholders = {};

  int count = 0;

  PoiholderCollection();

  int get length => poiholders.length;

  bool get isEmpty => poiholders.isEmpty;

  void addPoiholder(Poiholder poiholder) {
    poiholders.add(poiholder);
    ++count;
  }

  void addAllPoiholder(List<Poiholder> poiholders) {
    poiholders.addAll(poiholders);
    count += poiholders.length;
  }

  void addPoidata(ILatLong latlong, TagholderCollection tagholderCollection) {
    Poiholder poiholder = Poiholder(position: latlong, tagholderCollection: tagholderCollection);
    poiholders.add(poiholder);
    ++count;
  }

  // bool contains(PointOfInterest poi) {
  //   assert(content == null);
  //   return poiholders.firstWhereOrNull((test) => test.poi == poi) != null;
  // }

  void writePoidata(Writebuffer writebuffer, bool debugFile, double tileLatitude, double tileLongitude, List<String> languagesPreferences) {
    PoiholderWriter poiholderWriter = PoiholderWriter();
    for (Poiholder poiholder in poiholders) {
      poiholderWriter.writePoidata(writebuffer, poiholder, debugFile, tileLatitude, tileLongitude, languagesPreferences);
    }
  }

  void countTags(TagholderModel model) {
    for (Poiholder poiholder in poiholders) {
      poiholder.tagholderCollection.reconnectPoiTags(model);
      poiholder.tagholderCollection.countTags();
    }
  }
}
