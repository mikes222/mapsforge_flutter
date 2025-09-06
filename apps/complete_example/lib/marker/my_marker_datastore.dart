import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter_core/model.dart';

class MyMarkerDatastore extends DefaultMarkerDatastore {
  late final StreamSubscription _subscription;

  /// The context menu adds circleMarkers.
  CircleMarker? _dragNdropMarker;

  ILatLong? _originalPosition;

  MyMarkerDatastore(MapModel mapModel) {
    _subscription = mapModel.dragNdropStream.listen((event) => _newDragNdropEvent(event));
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _newDragNdropEvent(DragNdropEvent event) {
    switch (event.type) {
      case DragNdropEventType.start:
        List<Marker> markers = getTappedMarkers(event);
        print("found markers: ${markers.length}");
        markers.removeWhere((element) => element is! CircleMarker);
        _dragNdropMarker = (markers.isNotEmpty ? markers.first : null) as CircleMarker?;
        if (_dragNdropMarker != null) {
          // in a real app you do not need this because the position comes from an external source and can be refetched when drag'n'drop is cancelled.
          _originalPosition = _dragNdropMarker!.latLong;
          _dragNdropMarker!.setStrokeColorFromNumber(Colors.red.toARGB32());
          markerChanged(_dragNdropMarker!);
        }
      case DragNdropEventType.cancel:
        if (_dragNdropMarker != null) {
          _dragNdropMarker!.setStrokeColorFromNumber(Colors.black.toARGB32());
          _dragNdropMarker!.setLatLong(_originalPosition!, event.projection);
          markerChanged(_dragNdropMarker!);
        }
        _dragNdropMarker = null;
        _originalPosition = null;
      case DragNdropEventType.move:
        if (_dragNdropMarker != null) {
          _dragNdropMarker!.setLatLong(event.latLong, event.projection);
          markerChanged(_dragNdropMarker!);
        }
      case DragNdropEventType.finish:
        if (_dragNdropMarker != null) {
          _dragNdropMarker!.setLatLong(event.latLong, event.projection);
          _dragNdropMarker!.setStrokeColorFromNumber(Colors.black.toARGB32());
          markerChanged(_dragNdropMarker!);
          // in production we would save the new position to the database
          _dragNdropMarker = null;
          _originalPosition = null;
        }
    }
  }
}
