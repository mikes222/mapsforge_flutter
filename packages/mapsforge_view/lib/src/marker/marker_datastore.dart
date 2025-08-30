import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/marker.dart';

/// A datastore for markers which can hold several markers. The idea is to create an api which is able to retrieve markers
/// - e.g. from database or servers - based on the currently visible boundary of the map.
/// See also [SingleMarkerOverlay] for an overlay which holds exactly one marker.
abstract class MarkerDatastore<T> {
  final ZoomlevelRange zoomlevelRange;

  BoundingBox? cachedBoundingBox;

  int cachedZoomlevel = -1;

  final int extendMeters;

  MarkerDatastore({required this.zoomlevelRange, this.extendMeters = 5000});

  /// The overlay calls this method whenever the zoomlevel changes to give the datastore the possibility to initialize its markers for the new
  /// zoomlevel.
  Future<void> askChangeZoomlevel(int zoomlevel, BoundingBox boundingBox, PixelProjection projection) async {
    if (!zoomlevelRange.isWithin(zoomlevel)) return;
    cachedZoomlevel = zoomlevel;
    cachedBoundingBox = boundingBox.extendMeters(extendMeters);
    retrieveMarkersFor(cachedBoundingBox!, cachedZoomlevel);
  }

  /// The overlay calls this method whenever the map moves outside the previous bounding box. Note that the overlay extends the currently visible view by
  /// [extendMeters] to avoid refetching markers everytime the map moves.
  /// todo shoud this method be async?
  void askChangeBoundingBox(BoundingBox boundingBox) {
    if (cachedBoundingBox?.containsBoundingBox(boundingBox) == false) {
      return;
    }
    if (!zoomlevelRange.isWithin(cachedZoomlevel)) return;
    cachedBoundingBox = boundingBox.extendMeters(extendMeters);
    retrieveMarkersFor(cachedBoundingBox!, cachedZoomlevel);
  }

  /// The overlay calls this method to retrieve the markers which should be painted.
  List<Marker<T>> askRetrieveMarkersToPaint() {
    if (!zoomlevelRange.isWithin(cachedZoomlevel)) return const [];
    return retrieveMarkersToPaint();
  }

  /// This method returns the markers which should be painted for the given [zoomlevel] and [boundingBox].
  /// todo should this method be async?
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
