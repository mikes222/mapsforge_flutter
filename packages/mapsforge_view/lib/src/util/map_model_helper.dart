import 'package:dart_common/datastore.dart';
import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_view/mapsforge.dart';

class MapModelHelper {
  static Future<MapModel> createOfflineMapModel({
    String renderthemeFilename = "assets/defaultrender.xml",
    required Datastore datastore,
    ZoomlevelRange zoomlevelRange = const ZoomlevelRange.standard(),
  }) async {
    // Read the rendertheme from the assets folder.
    String renderthemeString = await rootBundle.loadString(renderthemeFilename);
    Rendertheme rendertheme = RenderThemeBuilder.createFromString(renderthemeString.toString());

    // The renderer converts the compressed data from mapfile to images. The rendertheme defines how the data should be rendered (size, colors, etc).
    DatastoreRenderer renderer = DatastoreRenderer(datastore, rendertheme, false);
    // Now instantiate our mapModel with the desired parameters. Our map does not support zoomlevel beyond 21 so restrict the zoomlevel range.
    MapModel mapModel = MapModel(renderer: renderer, zoomlevelRange: zoomlevelRange);
    return mapModel;
  }
}
