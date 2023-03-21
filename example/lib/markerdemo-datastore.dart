import 'dart:async';

import 'package:mapsforge_example/markerdemo-database.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';

/// a Datastore holds markers and decides which markers to show for a given zoomLevel
/// and boundary. This example is a bit more complex. Initially we do not have
/// any morkers but we can add some with the contextMenu. The contextMenu adds
/// items to the "database" and the database triggers events. This datastore
/// listens to these events and updates the UI accordingly.
/// This example reflects a real-world example with async changes. I hope it
/// clarifies a lot.
class MarkerdemoDatastore extends MarkerByItemDataStore {
  final SymbolCache symbolCache;

  late StreamSubscription _subscription;

  CircleMarker<TapEvent>? _moveMarker;

  final DisplayModel displayModel;

  MarkerdemoDatastore({required this.symbolCache, required this.displayModel}) {
    _subscription = MarkerdemoDatabase.observe.listen((event) async {
      // there are changes in the database
      // do the necessary operation and trigger repaint()

      if (event is AddMarkerEvent) {
        Marker marker = await _createMarker(event.tapEvent);
        addMarker(marker);
        setRepaint();
      } else if (event is RemoveMarkerEvent) {
        removeMarker(event.markerToRemove);
        setRepaint();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Future<void> retrieveMarkersFor(BoundingBox boundary, int zoomLevel) async {
    int count = 0;
    for (TapEvent tapEvent in MarkerdemoDatabase.databaseItems) {
      if (getMarkerWithItem(tapEvent) != null) {
        // marker is already set in the datastore, do nothing
        continue;
      }
      if (!boundary.containsLatLong(tapEvent)) continue;
      addMarker(await _createMarker(tapEvent));
      ++count;
    }
    // we are working async (as usual when working with databases). Now we have
    // added all markers for the given boundary. Now request a repaint()
    if (count > 0) setRepaint();
  }

  Future<CircleMarker<TapEvent>> _createMarker(TapEvent tapEvent) async {
    CircleMarker<TapEvent> marker = CircleMarker<TapEvent>(
      center: tapEvent,
      item: tapEvent,
      radius: 20,
      strokeWidth: 5,
      displayModel: displayModel,
    );
    return marker;
  }

  void moveMarkerStart(MoveAroundEvent event) {
    List<Marker> markers = isTapped(event);
    _moveMarker =
        markers.isNotEmpty ? markers.first as CircleMarker<TapEvent> : null;
    if (_moveMarker == null) return;
    _moveMarker!.setStrokeColorFromNumber(0xffff0000);
    setRepaint();
  }

  void moveMarkerCancel(MoveAroundEvent event) {
    if (_moveMarker == null) return;
    _moveMarker!.setStrokeColorFromNumber(0xff000000);
    _moveMarker = null;
    setRepaint();
  }

  Future<void> moveMarkerUpdate(MoveAroundEvent event) async {
    if (_moveMarker == null) return;
    _moveMarker!.setLatLong(LatLong(event.latitude, event.longitude));
    setRepaint();
  }

  void moveMarkerEnd(MoveAroundEvent event) {
    if (_moveMarker == null) return;
    MarkerdemoDatabase.move(
        _moveMarker!.item!, event.latitude, event.longitude);
    _moveMarker!.setStrokeColorFromNumber(0xff000000);
    setRepaint();
    _moveMarker = null;
  }
}
