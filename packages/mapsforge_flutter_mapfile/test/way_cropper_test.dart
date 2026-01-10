import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/filter.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:test/test.dart';

void main() async {
  setUpAll(() async {});

  /// Unhandled exception:
  // 'package:mapsforge_flutter_mapfile/src/filter/way_cropper.dart': Failed assertion: line 52 pos 16: '!result.isClosedWay()': result is not an open way Waypath{_path: 3 items, _closed: true, _boundingBox: null}
  // [MicroLatLong{_latitude: 51990754, _longitude: 4515011}, MicroLatLong{_latitude: 51990829, _longitude: 4515223}, MicroLatLong{_latitude: 51990871, _longitude: 4515269}, MicroLatLong{_latitude: 51990974, _longitude: 4515344},
  // MicroLatLong{_latitude: 51991103, _longitude: 4515405}, MicroLatLong{_latitude: 51991231, _longitude: 4515508}, MicroLatLong{_latitude: 51991402, _longitude: 4515771}, MicroLatLong{_latitude: 51991777, _longitude: 4516444},
  // MicroLatLong{_latitude: 51992011, _longitude: 4516969}, MicroLatLong{_latitude: 51992361, _longitude: 4517953}, MicroLatLong{_latitude: 51992506, _longitude: 4518489}, MicroLatLong{_latitude: 51993044, _longitude: 4520867}]
  // [LatLong{51.99139208973332/4.515755757893931}, MicroLatLong{_latitude: 51991402, _longitude: 4515771}, LatLong{51.99141417311275/4.5157928466796875}]
  // for boundary BoundingBox{minLatitude: 51.991392, minLongitude: 4.509476, maxLatitude: 51.995282, maxLongitude: 4.515793}, maxZoomlevel 19
  // #0      _AssertionError._doThrowNew (dart:core-patch/errors_patch.dart:67:4)
  // #1      _AssertionError._throwNew (dart:core-patch/errors_patch.dart:49:5)
  // #2      WayCropper.cropWay (package:mapsforge_flutter_mapfile/src/filter/way_cropper.dart:52:16)
  // #3      TileWriter._filterForTile.<anonymous closure> (package:mapsforge_flutter_mapfile/src/writer/tile_writer.dart:182:46)
  // #4      WayholderFileCollection.forEach (package:mapfile_converter/modifiers/wayholder_file_collection.dart:115:13)
  // #5      TileWriter._filterForTile (package:mapsforge_flutter_mapfile/src/writer/tile_writer.dart:177:33)
  // <asynchronous suspension>
  // #6      TileWriter.writeTile (package:mapsforge_flutter_mapfile/src/writer/tile_writer.dart:221:37)

  test("Crop data", () {
    List<ILatLong> path = [
      MicroLatLong(51990754, 4515011), // lat outside, lon inside
      MicroLatLong(51990829, 4515223),
      MicroLatLong(51990871, 4515269),
      MicroLatLong(51990974, 4515344),
      MicroLatLong(51991103, 4515405),
      MicroLatLong(51991231, 4515508), // lat outside, lon inside
      MicroLatLong(51991402, 4515771), // lat inside, lon inside
      MicroLatLong(51991777, 4516444), // lat inside, lon outside
      MicroLatLong(51992011, 4516969),
      MicroLatLong(51992361, 4517953),
      MicroLatLong(51992506, 4518489),
      MicroLatLong(51993044, 4520867), // lat inside, lon outside
    ];
    expect(LatLongUtils.isClosedWay(path), isFalse);

    Wayholder wayholder = Wayholder(tagholderCollection: TagholderCollection.empty());
    wayholder.openOutersAdd(Waypath(path: path));
    WayCropper cropper = const WayCropper();
    BoundingBox boundingBox = const BoundingBox(51.991392, 4.509476, 51.995282, 4.515793);
    Wayholder? result = cropper.cropWay(wayholder, boundingBox, 19);
    expect(result, isNotNull);
    print("wayholder $wayholder, result $result");
    expect(result!.openOutersRead.first.isClosedWay(), isFalse);
    // [LatLong{51.99139208973332/4.515755757893931}, MicroLatLong{_latitude: 51991402, _longitude: 4515771}, LatLong{51.99141417311275/4.5157928466796875}]
  });
}
