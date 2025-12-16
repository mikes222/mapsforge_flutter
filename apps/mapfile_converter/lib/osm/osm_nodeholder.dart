import 'package:mapsforge_flutter_core/model.dart';

class OsmNodeholder {
  int useCount = 0;

  final ILatLong latLong;

  final int layer;

  final TagCollection tagCollection;

  OsmNodeholder({required this.latLong, required this.layer, required this.tagCollection});

  @override
  String toString() {
    return 'OsmNodeholder{tags: $tagCollection}';
  }

  String toStringWithoutNames() {
    return 'OsmNodeholder{tags: ${tagCollection.printTagsWithoutNames()}';
  }
}
