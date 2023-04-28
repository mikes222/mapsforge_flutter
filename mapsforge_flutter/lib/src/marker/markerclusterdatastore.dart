import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';

///
/// Holds a collection of markers. Marker can only be of type [BasicPointMarker] (e.g. restaurants)
///
class MarkerClusterDataStore extends IMarkerDataStore {
  final List<BasicPointMarker> _markers = [];

  BoundingBox? _previousBoundingBox;

  int _previousZoomLevel = -1;

  List<BasicPointMarker> _previousMarkers = [];

  /// how large to extend a bounding area. When retrieving markers we extend
  /// the bounding area a bit. By doing so we retrieve a bit more markers than
  /// actually needed right now but we do not need to retrieve markers again
  /// as long as the view does not extend the extended bounding area by
  /// moving the map outside. This saves cpu. Measurements in meters.
  final int extendMeters;

  final int minClusterItems;

  final DisplayModel displayModel;

  MarkerClusterDataStore(
      {this.extendMeters = 1000,
      this.minClusterItems = 3,
      required this.displayModel})
      : assert(minClusterItems >= 2);

  /// returns the markers to draw for the given [boundary]. If this method needs more time return an empty list and call [setRepaint()] when finished.
  @override
  List<Marker> getMarkersToPaint(BoundingBox boundary, int zoomLevel) {
    BoundingBox extended = boundary.extendMeters(extendMeters);
    if (_previousBoundingBox != null &&
        _previousBoundingBox!.containsBoundingBox(boundary) &&
        zoomLevel == _previousZoomLevel) {
      return _previousMarkers;
    }
    retrieveMarkersFor(extended, zoomLevel);
    _previousBoundingBox = extended;
    _previousZoomLevel = zoomLevel;
    List<BasicPointMarker> markersToDraw = _markers
        .where((marker) => marker.shouldPaint(extended, zoomLevel))
        .toList();
    _previousMarkers.forEach((element) {
      if (element is _ClusterMarker) element.dispose();
    });
    _previousMarkers.clear();
    if (zoomLevel < 15) {
      MarkerGrid markerGrid = MarkerGrid(boundingBox: extended);
      markersToDraw.forEach((element) {
        markerGrid.addMarker(element);
      });
      markerGrid.markers.forEach((key, List<BasicPointMarker> value) {
        if (value.length < minClusterItems) {
          _previousMarkers.addAll(value);
        } else {
          BasicPointMarker clusterMarker = createClusterMarker(value);
          _previousMarkers.add(clusterMarker);
        }
      });
    } else {
      // for high zoom levels show all markers even if they are at the total same position
      _previousMarkers = markersToDraw;
    }
    return _previousMarkers;
  }

  BasicPointMarker createClusterMarker(List<BasicPointMarker> markers) {
    ILatLong latLong = markers.first.latLong;
    //print("Creating marker at $latLong for ${markers.length} items");
    return _ClusterMarker(
      center: latLong,
      radius: 18,
      strokeWidth: 3,
      strokeColor: 0xffffffff,
      fillColor: 0xaaff0000,
      displayModel: displayModel,
      markerCaption: MarkerCaption(
        text: "${markers.length}",
        latLong: latLong,
        fontSize: 18,
        fillColor: 0xffffffff,
        displayModel: displayModel,
      ),
    );
  }

  /// This method will be called if boundary or zoomlevel changes to give the implementation the chance to replace/retrieve markers for the new boundary/zoomlevel.
  /// If this method changes something asynchronously it must call [setRepaint] afterwards.
  void retrieveMarkersFor(BoundingBox boundary, int zoomLevel) {}

  @override
  void dispose() {
    super.dispose();
    clearMarkers();
  }

  /// Adds a new marker. Note that you may need to call setRepaint() afterwards.
  /// It is not called automatically because often we want to modify many
  /// markers at once without repainting after every modification.
  void addMarker(BasicPointMarker marker) {
    _markers.add(marker);
    _previousZoomLevel = -1;
  }

  void removeMarker(BasicPointMarker marker) {
    _markers.remove(marker);
    marker.dispose();
    _previousMarkers.remove(marker);
  }

  void clearMarkers() {
    _markers.forEach((marker) {
      marker.dispose();
    });
    _markers.clear();
    _previousMarkers.clear();
  }

  @override
  List<Marker> isTapped(TapEvent tapEvent) {
    return _previousMarkers
        .where((element) => element.isTapped(tapEvent))
        .toList();
  }
}

/////////////////////////////////////////////////////////////////////////////

/// Provides a grid for the given bounding box and stores each marker in its respective cell. When retrieving the markers by cells the user
/// can decide to show the marker itself or a cluster-marker instead of several markers of the same cell.
class MarkerGrid {
  final BoundingBox boundingBox;

  final int gridCount = 10;

  late double latDiff;

  late double lonDiff;

  Map<int, List<BasicPointMarker>> markers = {};

  MarkerGrid({required this.boundingBox}) {
    latDiff = boundingBox.maxLatitude - boundingBox.minLatitude;
    lonDiff = boundingBox.maxLongitude - boundingBox.minLongitude;
    assert(latDiff > 0);
    assert(lonDiff > 0);
  }

  void addMarker(BasicPointMarker marker) {
    double gridLat = (marker.latLong.latitude - boundingBox.minLatitude) /
        latDiff *
        gridCount;
    double gridLon = (marker.latLong.longitude - boundingBox.minLongitude) /
        lonDiff *
        gridCount;
    // if (gridLat < 0 || gridLat >= gridCount) return;
    // if (gridLon < 0 || gridLon >= gridCount) return;
    assert(gridLat >= 0);
    assert(gridLat < gridCount, "$gridLat vs $gridCount");
    assert(gridLon >= 0);
    assert(gridLon < gridCount, "$gridLon vs $gridCount");
    List<BasicPointMarker>? ms =
        markers[gridLat.floor() * gridCount + gridLon.floor()];
    if (ms == null) {
      ms = [];
      markers[gridLat.floor() * gridCount + gridLon.floor()] = ms;
    }
    ms.add(marker);
  }
}

/////////////////////////////////////////////////////////////////////////////

class _ClusterMarker extends CircleMarker {
  _ClusterMarker({
    Display display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    item,
    MarkerCaption? markerCaption,
    required ILatLong center,
    double radius = 10,
    int? percent,
    int? fillColor,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
    required DisplayModel displayModel,
  }) : super(
            display: display,
            minZoomLevel: minZoomLevel,
            maxZoomLevel: maxZoomLevel,
            item: item,
            markerCaption: markerCaption,
            center: center,
            radius: radius,
            percent: percent,
            fillColor: fillColor,
            strokeWidth: strokeWidth,
            strokeColor: strokeColor,
            displayModel: displayModel);
}
