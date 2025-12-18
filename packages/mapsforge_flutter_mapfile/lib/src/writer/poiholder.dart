import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tagholder_mixin.dart';

/// A data holder for a single Point of Interest (POI) during the map file
/// writing process.
///
/// This class encapsulates a [PointOfInterest] and uses the [TagholderMixin]
/// to manage the analysis and serialization of its tags.
class Poiholder {
  final PointOfInterest poi;

  TagholderMixin? _tagholder;

  Poiholder(this.poi);

  void createTagholder(List<Tagholder> tagsArray, List<String> languagesPreference) {
    if (_tagholder != null) return;
    _tagholder = TagholderMixin();
    _tagholder!.analyzeTags(poi.tags, tagsArray, languagesPreference);
  }

  TagholderMixin getTagholder() => _tagholder!;
}
