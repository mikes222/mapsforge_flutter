import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';

/// A datastore for markers which can hold several markers. The idea is to create an api which is able to retrieve markers
/// - e.g. from database or servers - based on the currently visible boundary of the map.
/// See also [SingleMarkerOverlay] for an overlay which holds exactly one marker.
abstract class MarkerDatastore<T> with ChangeNotifier {
  MarkerDatastore();

  /// Some markers (e.g. [PoiMarker]) needs a disposal.
  @override
  void dispose();

  /// The overlay calls this method whenever the zoomlevel changes to give the datastore the possibility to initialize its markers for the new
  /// zoomlevel.
  void askChangeZoomlevel(int zoomlevel, BoundingBox boundingBox, PixelProjection projection);

  /// The overlay calls this method whenever the map moves outside the previous bounding box. Note that the overlay extends the currently visible view by
  /// [extendMeters] to avoid refetching markers everytime the map moves. It is guaranteed that the zoomlevel is not changed when calling this method.
  void askChangeBoundingBox(int zoomlevel, BoundingBox boundingBox);

  /// The overlay calls this method to retrieve the markers which should be painted on the screen.
  Iterable<Marker<T>> askRetrieveMarkersToPaint();

  /// Adds a new marker. Note that you may need to call setRepaint() afterwards.
  /// It is not called automatically because often we want to modify many
  /// markers at once without repainting after every modification.
  void addMarker(Marker<T> marker);

  void addMarkers(Iterable<Marker<T>> markers);

  /// Removes a marker from this datastore
  void removeMarker(Marker<T> marker);

  /// Removes all markers from this datastore
  void clearMarkers();

  /// Should be called if a merker has been changed and needs a reinit
  void markerChanged(Marker<T> marker);

  /// Returns all markers which are in the area marked by the given event.
  List<Marker<T>> getTappedMarkers(TapEvent event);

  /// Notifies the ui about a necessary repaint because something has been changed
  void requestRepaint() {
    try {
      notifyListeners();
    } catch (error) {
      // ignore that error
    }
  }
}
