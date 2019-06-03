import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/cache/tilecache.dart';
import 'package:mapsforge_flutter/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/layer/job/jobrenderer.dart';

import 'displaymodel.dart';
import 'mapviewposition.dart';

class MapModel {
  final DisplayModel displayModel;

  //final MapViewDimension mapViewDimension;
  final GraphicFactory graphicsFactory;
  final TileCache tileCache;
  final JobRenderer renderer;
  MapViewPosition mapViewPosition;

  MapModel({
    @required this.displayModel,
    @required this.renderer,
    @required this.graphicsFactory,
    @required this.tileCache,
  })  : assert(displayModel != null),
        assert(renderer != null),
        assert(graphicsFactory != null),
        assert(tileCache != null);
//mapViewDimension = MapViewDimension();
}
