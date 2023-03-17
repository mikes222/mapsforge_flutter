import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/marker.dart';

abstract class IMarkerDataStore extends ChangeNotifier {
  bool _disposed = false;

  List<Marker> getMarkersToPaint(BoundingBox boundary, int zoomLevel);

  /// called if the user taps at the screen. The method will return a list of
  /// markers which are considered as "tapped by the user"
  List<Marker> isTapped(TapEvent tapEvent);

  bool get disposed => _disposed;

  @override
  @mustCallSuper
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Triggers a repaint of the markers for this datastore
  void setRepaint() {
    try {
      notifyListeners();
    } catch (error, stacktrace) {
      // ignore that error
    }
  }

  /// https://stackoverflow.com/questions/63884633/unhandled-exception-a-changenotifier-was-used-after-being-disposed
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
