import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/wayholder_writer.dart';

/// A helper class to hold all ways for a specific zoom level during the
/// sub-file creation process.
class WayholderCollection {
  Set<Wayholder> wayholders = {};

  int count = 0;

  WayholderCollection();

  int get nodeCount {
    int result = 0;
    for (var wayholder in wayholders) {
      result += wayholder.nodeCount();
    }
    return result;
  }

  bool get isEmpty => wayholders.isEmpty;

  int get length => wayholders.length;

  void addWayholder(Wayholder wayholder) {
    assert(wayholder.openOutersRead.isNotEmpty || wayholder.closedOutersRead.isNotEmpty);
    wayholders.add(wayholder);
    ++count;
    //count += wayholder.openOuters.length + wayholder.closedOuters.length;
  }

  void addWayholders(Iterable<Wayholder> wayholders) {
    for (var test in wayholders) {
      assert(test.openOutersRead.isNotEmpty || test.closedOutersRead.isNotEmpty);
    }
    this.wayholders.addAll(wayholders);
    count += wayholders.length;
    //count += wayholders.fold(0, (combine, test) => combine + test.openOuters.length + test.closedOuters.length);
  }

  void writeWaydata(Writebuffer writebuffer, bool debugFile, Tile tile, double tileLatitude, double tileLongitude, List<String> languagesPreferences) {
    WayholderWriter wayholderWriter = WayholderWriter();
    for (Wayholder wayholder in wayholders) {
      wayholderWriter.writeWaydata(writebuffer, wayholder, debugFile, tile, tileLatitude, tileLongitude, languagesPreferences);
    }
  }

  void countTags(TagholderModel model) {
    for (Wayholder wayholder in wayholders) {
      wayholder.tagholderCollection.reconnectWayTags(model);
      wayholder.tagholderCollection.countTags();
    }
  }
}
