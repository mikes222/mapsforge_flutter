import 'package:mapfile_converter/modifiers/poiholder_file_collection.dart';
import 'package:mapfile_converter/modifiers/wayholder_file_collection.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class HolderCollectionFileImplementation implements HolderCollectionImplementation {
  final int size;

  HolderCollectionFileImplementation(this.size);

  @override
  IPoiholderCollection createPoiholderCollection(String prefix) {
    return PoiholderFileCollection(filename: "${prefix}_pois_${HolderCollectionFactory.randomId}.tmp", spillBatchSize: size * 5);
  }

  @override
  IWayholderCollection createWayholderCollection(String prefix) {
    return WayholderFileCollection(filename: "${prefix}_ways_${HolderCollectionFactory.randomId}.tmp", spillBatchSize: size);
  }
}
