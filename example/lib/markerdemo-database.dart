import 'package:mapsforge_flutter/core.dart';
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

  static Subject<DatabaseEvent> _inject = BehaviorSubject<DatabaseEvent>();

  static Stream<DatabaseEvent> get observe => _inject.stream;

  static void addToDatabase(TapEvent tapEvent) {
    events.add(tapEvent);
    // now inform listeners about changes in the database
    _inject.add(DatabaseEvent(tapEvent));
  }
}

/////////////////////////////////////////////////////////////////////////////

class DatabaseEvent {
  final TapEvent tapEvent;

  const DatabaseEvent(this.tapEvent);
}
