import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/cache/tilecache.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/layer/job/jobrenderer.dart';
import 'package:rxdart/rxdart.dart';

import 'displaymodel.dart';
import 'mapviewdimension.dart';
import 'mapviewposition.dart';

class MapModel {
  final DisplayModel displayModel;
  final MapViewDimension mapViewDimension;
  final GraphicFactory graphicsFactory;
  final TileCache tileCache;
  final JobRenderer renderer;
  MapViewPosition _mapViewPosition;

  Subject<MapViewPosition> _inject = PublishSubject();
  Observable<MapViewPosition> _observe;

  MapModel({
    @required this.displayModel,
    @required this.renderer,
    @required this.graphicsFactory,
    @required this.tileCache,
  })  : assert(displayModel != null),
        assert(renderer != null),
        assert(graphicsFactory != null),
        assert(tileCache != null),
        mapViewDimension = MapViewDimension() {
    _observe = _inject.asBroadcastStream();
  }

  Observable<MapViewPosition> get observe => _observe;

  MapViewPosition get mapViewPosition => _mapViewPosition;

  void setMapViewPosition(double latitude, double longitude) {
    if (_mapViewPosition != null && _mapViewPosition.latitude == latitude && _mapViewPosition.longitude == longitude) return;
    MapViewPosition newPosition = MapViewPosition(latitude, longitude, _mapViewPosition?.zoomLevel ?? 14);
    _mapViewPosition = newPosition;
    _inject.add(newPosition);
  }

  void zoomIn() {
    MapViewPosition newPosition = MapViewPosition(_mapViewPosition?.latitude, _mapViewPosition?.longitude, _mapViewPosition?.zoomLevel + 1);
    _mapViewPosition = newPosition;
    _inject.add(newPosition);
  }

  void zoomOut() {
    MapViewPosition newPosition = MapViewPosition(_mapViewPosition?.latitude, _mapViewPosition?.longitude, _mapViewPosition?.zoomLevel - 1);
    _mapViewPosition = newPosition;
    _inject.add(newPosition);
  }
}
