import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/cache/tilecache.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/layer/job/jobrenderer.dart';
import 'package:rxdart/rxdart.dart';

import 'displaymodel.dart';
import 'mapviewdimension.dart';
import 'mapviewposition.dart';

class MapModel {
  final int DEFAULT_ZOOM = 10;
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
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition(latitude, longitude, _mapViewPosition.zoomLevel);
      _mapViewPosition = newPosition;
      _inject.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(latitude, longitude, DEFAULT_ZOOM);
      _mapViewPosition = newPosition;
      _inject.add(newPosition);
    }
  }

  void zoomIn() {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.zoomIn(_mapViewPosition);
      _mapViewPosition = newPosition;
      _inject.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM + 1);
      _mapViewPosition = newPosition;
      _inject.add(newPosition);
    }
  }

  void zoomOut() {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.zoomOut(_mapViewPosition);
      _mapViewPosition = newPosition;
      _inject.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM - 1);
      _mapViewPosition = newPosition;
      _inject.add(newPosition);
    }
  }

  void setLeftUpper(double left, double upper) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition =
          MapViewPosition.setLeftUpper(_mapViewPosition, left, upper, displayModel.tileSize, mapViewDimension.getDimension());
      _mapViewPosition = newPosition;
      _inject.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM - 1);
      _mapViewPosition = newPosition;
      _inject.add(newPosition);
    }
  }
}
