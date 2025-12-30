import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

/// A data holder for a single Point of Interest (POI) during the map file
/// writing process.
///
/// This class encapsulates a [PointOfInterest] and uses the [TagholderMixin]
/// to manage the analysis and serialization of its tags.
class Poiholder implements ILatLong {
  final ILatLong position;

  final TagholderCollection tagholderCollection;

  Poiholder({required this.position, required this.tagholderCollection});

  String toStringWithoutNames() {
    return 'Poiholder{position: $position, tagholderCollection: ${tagholderCollection.printTagsWithoutNames()}';
  }

  @override
  double get latitude => position.latitude;

  @override
  double get longitude => position.longitude;
}
