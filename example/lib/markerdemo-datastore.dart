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

  MarkerdemoDatastore({required this.symbolCache}) {
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
    for (TapEvent tapEvent in MarkerdemoDatabase.events) {
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

  Future<Marker> _createMarker(TapEvent tapEvent) async {
    CircleMarker marker = CircleMarker(
      center: tapEvent,
      item: tapEvent,
      radius: 20,
      strokeWidth: 5,
    );
    return marker;
  }
}
