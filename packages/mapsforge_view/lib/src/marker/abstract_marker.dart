import 'package:flutter/material.dart';
import 'package:mapsforge_view/src/marker/marker.dart';

/// Abstract Marker class for further extensions. This class handles the caption of a marker.
abstract class AbstractMarker<T> extends Marker<T> {
  AbstractMarker({super.zoomlevelRange, super.item});

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }
}
