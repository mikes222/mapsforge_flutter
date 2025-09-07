import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

class MapModelHelper {
  /// A helper function to create a mapModel from a mapfile. Note that the mapModel must be disposed after use.
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

  /// A helper function to create a mapModel from a mapfile. Note that the mapModel must be disposed after use.
  static Future<MapModel> createOnlineMapModel({required Renderer renderer, ZoomlevelRange zoomlevelRange = const ZoomlevelRange.standard()}) async {
    // Now instantiate our mapModel with the desired parameters. Our map does not support zoomlevel beyond 21 so restrict the zoomlevel range.
    MapModel mapModel = MapModel(renderer: renderer, zoomlevelRange: zoomlevelRange);
    return mapModel;
  }
}
