import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/marker.dart';

abstract class IMarkerDataStore extends ChangeNotifier {
  bool _disposed = false;

  List<Marker> getMarkersToPaint(BoundingBox boundary, int zoomLevel);

  List<Marker> isTapped(
      MapViewPosition mapViewPosition, double tappedX, double tappedY);

  bool get disposed => _disposed;

  @override
  @mustCallSuper
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setRepaint() {
    try {
      if (!_disposed) notifyListeners();
    } catch (error, stacktrace) {
      // ignore that error
    }
  }
}
