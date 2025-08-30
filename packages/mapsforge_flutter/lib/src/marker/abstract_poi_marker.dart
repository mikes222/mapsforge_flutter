import 'package:dart_rendertheme/rendertheme.dart';
import 'package:mapsforge_flutter/src/marker/abstract_marker.dart';
import 'package:mapsforge_flutter/src/marker/caption_reference.dart';
import 'package:mapsforge_flutter_core/model.dart';

/// Abstract Marker class for further extensions. This class holds the position of a marker as [ILatLong] and implements the shouldPaint() method.
abstract class AbstractPoiMarker<T> extends AbstractMarker<T> implements ILatLong, SymbolSearcher, CaptionReference {
  ///
  /// The position in the map if the current marker is a "point".
  ///
  ILatLong latLong;

  AbstractPoiMarker({super.zoomlevelRange, required this.latLong, super.key});

  /// returns true if the marker should be painted. The [boundary] represents the currently visible area
  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return super.shouldPaint(boundary, zoomLevel) && boundary.contains(latLong.latitude, latLong.longitude);
  }

  @override
  double get latitude => latLong.latitude;

  @override
  double get longitude => latLong.longitude;

  @override
  ILatLong getReference() {
    return latLong;
  }
}
