import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/abstract_poi_marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/util.dart';

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
  bool _disposed = false;

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
    _disposed = true;
    super.dispose();
  }

  bool get disposed => _disposed;

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
    if (markersToPaint.isEmpty) {
      _clusteredMarkers[_zoomlevel] = clustered;
      return;
    }

    final SpatialPositionIndex<AbstractPoiMarker> spatialIndex = SpatialPositionIndex(cellSize: _clusterDistance * 2);
    for (var marker in markersToPaint) {
      final point = _projection!.latLonToPixel(marker.latLong);
      spatialIndex.add(marker, point);
    }

    for (final list in spatialIndex.getGrid().values) {
      if (list.length > 1) {
        double totalLat = 0;
        double totalLon = 0;
        for (final neighbor in list) {
          totalLat += neighbor.latLong.latitude;
          totalLon += neighbor.latLong.longitude;
        }
        final clusterPosition = LatLong(totalLat / list.length, totalLon / list.length);
        clustered.add(ClusterMarker(position: clusterPosition, markerCount: list.length));
      } else {
        clustered.add(list.first);
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
