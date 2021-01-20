import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/layer/job/jobrenderer.dart';
import 'package:mapsforge_flutter/src/marker/markerdatastore.dart';

import '../cache/tilebitmapcache.dart';
import 'displaymodel.dart';

class MapModel {
  final DisplayModel displayModel;
  final GraphicFactory graphicsFactory;
  final JobRenderer renderer;
  final List<MarkerDataStore> markerDataStores = List();
  final TileBitmapCache tileBitmapCache;

  MapModel({
    @required this.displayModel,
    @required this.renderer,
    @required this.graphicsFactory,
    this.tileBitmapCache,
  })  : assert(displayModel != null),
        assert(renderer != null),
        assert(graphicsFactory != null) {}

  void dispose() {
    markerDataStores.forEach((datastore) {
      datastore.dispose();
    });
    graphicsFactory.dispose();
    tileBitmapCache?.dispose();
  }
}
