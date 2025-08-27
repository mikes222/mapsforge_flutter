import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/marker.dart';

abstract class MarkerDatastore<T> {
  final ZoomlevelRange zoomlevelRange;

  BoundingBox? cachedBoundingBox;

  int cachedZoomlevel = -1;

  final int extendMeters;

  MarkerDatastore({required this.zoomlevelRange, this.extendMeters = 5000});

  Future<void> askChangeZoomlevel(int zoomlevel, BoundingBox boundingBox, PixelProjection projection) async {
    if (!zoomlevelRange.isWithin(zoomlevel)) return;
    cachedZoomlevel = zoomlevel;
    cachedBoundingBox = boundingBox.extendMeters(extendMeters);
    retrieveMarkersFor(cachedBoundingBox!, cachedZoomlevel);
  }

  void askChangeBoundingBox(BoundingBox boundingBox) {
    if (cachedBoundingBox?.containsBoundingBox(boundingBox) == false) {
      return;
    }
    if (!zoomlevelRange.isWithin(cachedZoomlevel)) return;
    cachedBoundingBox = boundingBox.extendMeters(extendMeters);
    retrieveMarkersFor(cachedBoundingBox!, cachedZoomlevel);
  }

  List<Marker<T>> askRetrieveMarkersToPaint() {
    if (!zoomlevelRange.isWithin(cachedZoomlevel)) return const [];
    return retrieveMarkersToPaint();
  }

  void retrieveMarkersFor(BoundingBox boundingBox, int zoomlevel);

  List<Marker<T>> retrieveMarkersToPaint();

  /// Adds a new marker. Note that you may need to call setRepaint() afterwards.
  /// It is not called automatically because often we want to modify many
  /// markers at once without repainting after every modification.
  void addMarker(Marker<T> marker);

  /// Removes all markers from this datastore
  void clearMarkers();

  List<Marker<T>> getTappedMarkers(TapEvent event);
}
