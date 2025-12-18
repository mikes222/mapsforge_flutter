import 'dart:typed_data';

import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tagholder_mixin.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/wayholder_writer.dart';

/// A helper class to hold all ways for a specific zoom level during the
/// sub-file creation process.
class WayholderCollection {
  Set<Wayholder> wayholders = {};

  Uint8List? content;

  int wayCount = 0;

  WayholderCollection();

  int get nodeCount {
    int result = 0;
    for (var wayholder in wayholders) {
      result += wayholder.nodeCount();
    }
    return result;
  }

  void addWayholder(Wayholder wayholder) {
    assert(content == null);
    assert(wayholder.openOutersRead.isNotEmpty || wayholder.closedOutersRead.isNotEmpty);
    wayholders.add(wayholder);
    ++wayCount;
    //count += wayholder.openOuters.length + wayholder.closedOuters.length;
  }

  void addWayholders(List<Wayholder> wayholders) {
    for (var test in wayholders) {
      assert(test.openOutersRead.isNotEmpty || test.closedOutersRead.isNotEmpty);
    }
    assert(content == null);
    this.wayholders.addAll(wayholders);
    wayCount += wayholders.length;
    //count += wayholders.fold(0, (combine, test) => combine + test.openOuters.length + test.closedOuters.length);
  }

  // Wayholder? searchWayholder(Way way) {
  //   assert(content == null);
  //   return wayholders.firstWhereOrNull((test) => test.way == way);
  // }

  Uint8List writeWaydata(bool debugFile, Tile tile, double tileLatitude, double tileLongitude) {
    if (content != null) return content!;
    Writebuffer writebuffer = Writebuffer();
    WayholderWriter wayholderWriter = WayholderWriter();
    for (Wayholder wayholder in wayholders) {
      wayholderWriter.writeWaydata(writebuffer, wayholder, debugFile, tile, tileLatitude, tileLongitude);
    }
    wayholders.clear();
    content = writebuffer.getUint8List();
    return content!;
  }

  void createTagholders(List<Tagholder> tagsArray, List<String> languagesPreference) {
    for (Wayholder wayholder in wayholders) {
      wayholder.createTagholder(tagsArray, languagesPreference);
    }
  }
}
