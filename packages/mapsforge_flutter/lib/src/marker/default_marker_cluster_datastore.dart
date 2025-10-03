import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/abstract_poi_marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';

/// A [MarkerDatastore] that clusters markers to avoid cluttering the map.
///
/// This datastore wraps another [MarkerDatastore] and groups nearby markers
/// into a single [ClusterMarker] when they are too close to each other at the
/// current zoom level.
class DefaultMarkerClusterDatastore<T> extends MarkerDatastore {
  final MarkerDatastore<T> _markerDatastore;
  final int _clusterDistance;
  final Map<int, List<Marker>> _clusteredMarkers = {};

  int _zoomlevel = -1;
  BoundingBox? _boundingBox;
  PixelProjection? _projection;

  /// Creates a new [DefaultMarkerClusterDatastore].
  ///
  /// [markerDatastore] The underlying datastore that provides the markers.
  /// [clusterDistance] The distance in pixels within which markers are clustered.
  DefaultMarkerClusterDatastore({required MarkerDatastore<T> markerDatastore, int clusterDistance = 50})
    : _markerDatastore = markerDatastore,
      _clusterDistance = clusterDistance {
    _markerDatastore.addListener(_onDatastoreChanged);
  }

  @override
  void dispose() {
    _markerDatastore.removeListener(_onDatastoreChanged);
    super.dispose();
  }

  void _onDatastoreChanged() {
    // When the underlying datastore changes, we need to re-cluster.
    _cluster();
    requestRepaint();
  }

  @override
  void askChangeZoomlevel(int zoomlevel, BoundingBox boundingBox, PixelProjection projection) {
    _zoomlevel = zoomlevel;
    _boundingBox = boundingBox;
    _projection = projection;
    _markerDatastore.askChangeZoomlevel(zoomlevel, boundingBox, projection);
    _cluster();
  }

  @override
  void askChangeBoundingBox(int zoomlevel, BoundingBox boundingBox) {
    _boundingBox = boundingBox;
    _markerDatastore.askChangeBoundingBox(zoomlevel, boundingBox);
    _cluster();
  }

  @override
  Iterable<Marker> askRetrieveMarkersToPaint() {
    return _clusteredMarkers[_zoomlevel] ?? [];
  }

  void _cluster() {
    if (_zoomlevel == -1 || _boundingBox == null || _projection == null) {
      return;
    }

    final List<AbstractPoiMarker> markersToPaint = _markerDatastore.askRetrieveMarkersToPaint().toList().cast<AbstractPoiMarker>();
    final List<Marker> clustered = [];
    final List<bool> visited = List.filled(markersToPaint.length, false);

    for (int i = 0; i < markersToPaint.length; i++) {
      if (visited[i]) {
        continue;
      }

      final AbstractPoiMarker marker1 = markersToPaint[i];
      final List<AbstractPoiMarker> cluster = [marker1];
      visited[i] = true;

      final Mappoint point1 = _projection!.latLonToPixel(marker1.latLong);

      for (int j = i + 1; j < markersToPaint.length; j++) {
        if (visited[j]) {
          continue;
        }

        final AbstractPoiMarker marker2 = markersToPaint[j];
        final Mappoint point2 = _projection!.latLonToPixel(marker2.latLong);

        if (point1.distance(point2) < _clusterDistance) {
          cluster.add(marker2);
          visited[j] = true;
        }
      }

      if (cluster.length > 1) {
        final double avgLat = cluster.map((m) => m.latLong.latitude).reduce((a, b) => a + b) / cluster.length;
        final double avgLon = cluster.map((m) => m.latLong.longitude).reduce((a, b) => a + b) / cluster.length;
        final LatLong clusterPosition = LatLong(avgLat, avgLon);

        clustered.add(ClusterMarker(position: clusterPosition, markerCount: cluster.length));
      } else {
        clustered.add(marker1);
      }
    }
    _clusteredMarkers[_zoomlevel] = clustered;
  }

  // The following methods delegate to the underlying datastore.

  @override
  void addMarker(Marker marker) => _markerDatastore.addMarker(marker as Marker<T>);

  @override
  void addMarkers(Iterable<Marker> markers) => _markerDatastore.addMarkers(markers.cast<Marker<T>>());

  @override
  void clearMarkers() => _markerDatastore.clearMarkers();

  @override
  List<Marker> getTappedMarkers(TapEvent event) {
    final List<Marker> tapped = [];
    final markers = _clusteredMarkers[_zoomlevel] ?? [];
    for (final marker in markers) {
      if (marker.isTapped(event)) {
        tapped.add(marker);
      }
    }
    return tapped;
  }

  @override
  void markerChanged(Marker marker) => _markerDatastore.markerChanged(marker as Marker<T>);

  @override
  void removeMarker(Marker marker) => _markerDatastore.removeMarker(marker as Marker<T>);
}
