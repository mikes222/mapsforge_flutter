import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/cache/tilecache.dart';
import 'package:mapsforge_flutter/datastore/mapdatastore.dart';
import 'package:mapsforge_flutter/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/implementation/graphics/fluttergraphicsfactory.dart';
import 'package:mapsforge_flutter/layer/cache/MemoryTileCache.dart';
import 'package:mapsforge_flutter/rendertheme/rule/rendertheme.dart';

import 'displaymodel.dart';
import 'mapviewdimension.dart';
import 'mapviewposition.dart';

class MapModel {
  final DisplayModel displayModel;
  final MapViewDimension mapViewDimension;
  final GraphicFactory graphicsFactory = FlutterGraphicFactory();
  final TileCache tileCache = MemoryTileCache(50);
  MapViewPosition mapViewPosition;
  RenderTheme renderTheme;
  MapDataStore mapDataStore;

  MapModel(
      {@required this.displayModel,
      @required this.renderTheme,
      @required this.mapDataStore})
      : assert(displayModel != null),
        assert(renderTheme != null),
        assert(mapDataStore != null),
        mapViewDimension = MapViewDimension();
}
