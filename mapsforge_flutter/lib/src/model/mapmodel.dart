import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/cache/symbolcache.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/implementation/view/contextmenubuilder.dart';
import 'package:mapsforge_flutter/src/implementation/view/nopositionview.dart';
import '../cache/tilebitmapcache.dart';
import 'package:mapsforge_flutter/src/layer/job/jobrenderer.dart';
import 'package:mapsforge_flutter/src/marker/markerdatastore.dart';
import 'package:rxdart/rxdart.dart';

import 'displaymodel.dart';
import 'mappoint.dart';
import 'mapviewdimension.dart';
import 'mapviewposition.dart';

class MapModel {
  final int DEFAULT_ZOOM = 10;
  final int DEFAULT_INDOOR_LEVEL = 0;
  final DisplayModel displayModel;
  final MapViewDimension mapViewDimension;
  final GraphicFactory graphicsFactory;
  final JobRenderer renderer;
  final SymbolCache symbolCache;
  final List<MarkerDataStore> markerDataStores = List();
  final TileBitmapCache tileBitmapCache;
  NoPositionView noPositionView;
  MapViewPosition _mapViewPosition;
  ContextMenuBuilder contextMenuBuilder;

  Subject<MapViewPosition> _injectPosition = PublishSubject();
  Stream<MapViewPosition> _observePosition;

  Subject<TapEvent> _injectTap = PublishSubject();
  Stream<TapEvent> _observeTap;

  Subject<GestureEvent> _injectGesture = PublishSubject();
  Stream<GestureEvent> _observeGesture;

  MapModel({
    @required this.displayModel,
    @required this.renderer,
    @required this.graphicsFactory,
    @required this.symbolCache,
    this.noPositionView,
    this.tileBitmapCache,
    this.contextMenuBuilder,
  })  : assert(displayModel != null),
        assert(renderer != null),
        assert(graphicsFactory != null),
        assert(symbolCache != null),
        mapViewDimension = MapViewDimension() {
    _observePosition = _injectPosition.asBroadcastStream();

    _observeTap = _injectTap.asBroadcastStream();
    _observeGesture = _injectGesture.asBroadcastStream();
    if (noPositionView == null) noPositionView = NoPositionView();
  }

  void dispose() {
    markerDataStores.forEach((datastore) {
      datastore.dispose();
    });
    symbolCache.dispose();
    tileBitmapCache.dispose();
  }

  Stream<MapViewPosition> get observePosition => _observePosition;

  Stream<TapEvent> get observeTap => _observeTap;

  Stream<GestureEvent> get observeGesture => _observeGesture;

  MapViewPosition get mapViewPosition => _mapViewPosition;

  void setMapViewPosition(double latitude, double longitude) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition(latitude, longitude, _mapViewPosition.zoomLevel, _mapViewPosition.indoorLevel, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(latitude, longitude, DEFAULT_ZOOM, DEFAULT_INDOOR_LEVEL, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void zoomIn() {
    if (_mapViewPosition != null) {
      if (_mapViewPosition.zoomLevel >= displayModel.maxZoomLevel) return;
      MapViewPosition newPosition = MapViewPosition.zoomIn(_mapViewPosition);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM + 1, DEFAULT_INDOOR_LEVEL, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void zoomInAround(double latitude, double longitude) {
    if (_mapViewPosition != null) {
      if (_mapViewPosition.zoomLevel >= displayModel.maxZoomLevel) return;
      MapViewPosition newPosition = MapViewPosition.zoomInAround(_mapViewPosition, latitude, longitude);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      // without an old position we cannot calculate the location of the zoom-center, so use null instead
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM + 1, DEFAULT_INDOOR_LEVEL, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void zoomOut() {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.zoomOut(_mapViewPosition);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM - 1, DEFAULT_INDOOR_LEVEL, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  MapViewPosition setZoomLevel(int zoomLevel) {
    if (zoomLevel >= displayModel.maxZoomLevel) zoomLevel = displayModel.maxZoomLevel;
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.zoom(_mapViewPosition, zoomLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, zoomLevel, DEFAULT_INDOOR_LEVEL, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  void indoorLevelUp() {
    if (_mapViewPosition != null) {
      if (_mapViewPosition.zoomLevel >= displayModel.maxZoomLevel) return;
      MapViewPosition newPosition = MapViewPosition.indoorLevelUp(_mapViewPosition);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM, DEFAULT_INDOOR_LEVEL + 1, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void indoorLevelDown() {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.indoorLevelDown(_mapViewPosition);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM, DEFAULT_INDOOR_LEVEL - 1, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  MapViewPosition setIndoorLevel(int indoorLevel) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.setIndoorLevel(_mapViewPosition, indoorLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM, indoorLevel, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  MapViewPosition setScale(Mappoint focalPoint, double scale) {
    assert(scale != null);
    assert(scale > 0);
    if (_mapViewPosition != null) {
      //print("Scaling ${_mapViewPosition.zoomLevel} * $scale");
      if (MercatorProjectionImpl.zoomLevelToScaleFactor(_mapViewPosition.zoomLevel) * scale < 1) {
        scale = 1 / MercatorProjectionImpl.zoomLevelToScaleFactor(_mapViewPosition.zoomLevel);
      } else {
        double scaleFactor = MercatorProjectionImpl.zoomLevelToScaleFactor(_mapViewPosition.zoomLevel) * scale;
        if (scaleFactor > MercatorProjectionImpl.zoomLevelToScaleFactor(displayModel.maxZoomLevel)) {
          scale = MercatorProjectionImpl.zoomLevelToScaleFactor(displayModel.maxZoomLevel) /
              MercatorProjectionImpl.zoomLevelToScaleFactor(_mapViewPosition.zoomLevel);
        }
      }
      MapViewPosition newPosition = MapViewPosition.scale(_mapViewPosition, focalPoint, scale);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM, DEFAULT_INDOOR_LEVEL, displayModel.tileSize);
      newPosition = MapViewPosition.scale(newPosition, null, scale);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  void setLeftUpper(double left, double upper) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.setLeftUpper(_mapViewPosition, left, upper, mapViewDimension.getDimension());
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM - 1, DEFAULT_INDOOR_LEVEL, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void tapEvent(double left, double upper) {
    if (_mapViewPosition == null) return;
    _mapViewPosition.calculateBoundingBox(mapViewDimension.getDimension());
    TapEvent event = TapEvent(_mapViewPosition.mercatorProjection.pixelYToLatitude(_mapViewPosition.leftUpper.y + upper),
        _mapViewPosition.mercatorProjection.pixelXToLongitude(_mapViewPosition.leftUpper.x + left), left, upper);
    _injectTap.add(event);
  }

  void gestureEvent() {
    _injectGesture.add(GestureEvent());
  }
}

/////////////////////////////////////////////////////////////////////////////

class TapEvent {
  final double latitude;

  final double longitude;

  final double x;

  final double y;

  TapEvent(this.latitude, this.longitude, this.x, this.y)
      : assert(latitude != null),
        assert(longitude != null),
        assert(x != null),
        assert(y != null);
}

/////////////////////////////////////////////////////////////////////////////

class GestureEvent {}
