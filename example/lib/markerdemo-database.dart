import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:rxdart/rxdart.dart';

/// A simple "database" for demonstration purposes for markers. In our demo
/// the ContextMenu will add Markers to the database whereas the datastore will
/// receive informations about changes in the database, updates the markers
/// and triggers a redraw.
/// Note that it could be implemented easier too. This demo however decouples
/// the producer(s) of the markers from the view. It reflects the behavior of
/// many modern implementations.
/// For the sake of simplicity we use the already existing TapEvent in the database.
/// In a real world you would have your own structures representing whatever you
/// need to represent in the map - for example information about point of interests.
class MarkerdemoDatabase {
  static final List<TapEvent> events = [];

  static Subject<MarkerDatabaseEvent> _inject = BehaviorSubject<MarkerDatabaseEvent>();

  static Stream<MarkerDatabaseEvent> get observe => _inject.stream;

  static void addToDatabase(TapEvent tapEvent) {
    events.add(tapEvent);
    // now inform listeners about changes in the database
    _inject.add(AddMarkerEvent(tapEvent: tapEvent));
  }

  static void removeFromDatabase(TapEvent tapEvent, Marker markerToRemove) {
    events.remove(markerToRemove.item);

    _inject.add(RemoveMarkerEvent(markerToRemove: markerToRemove));
  }
}

/////////////////////////////////////////////////////////////////////////////

class AddMarkerEvent extends MarkerDatabaseEvent {
  final TapEvent tapEvent;

  AddMarkerEvent({required this.tapEvent});
}

class RemoveMarkerEvent extends MarkerDatabaseEvent {
  final Marker markerToRemove;

  RemoveMarkerEvent({
    required this.markerToRemove,
  });
}

abstract class MarkerDatabaseEvent {}
