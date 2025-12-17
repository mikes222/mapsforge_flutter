import 'package:mapsforge_flutter_core/model.dart';

class OsmNodeholder {
  int useCount = 0;

  final ILatLong latLong;

  final int layer;

  final TagCollection tagCollection;

  PointOfInterest? _pointOfInterest;

  OsmNodeholder({required this.latLong, required this.layer, required this.tagCollection});

  PointOfInterest createPoi() {
    if (_pointOfInterest != null) return _pointOfInterest!;
    PointOfInterest pointOfInterest = PointOfInterest(layer, tagCollection, latLong);
    _pointOfInterest = pointOfInterest;
    return pointOfInterest;
  }

  @override
  String toString() {
    return 'OsmNodeholder{tags: $tagCollection}';
  }

  String toStringWithoutNames() {
    return 'OsmNodeholder{tags: ${tagCollection.printTagsWithoutNames()}';
  }
}
