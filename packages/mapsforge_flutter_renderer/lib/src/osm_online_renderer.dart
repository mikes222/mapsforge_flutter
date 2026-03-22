import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/ui/tile_picture.dart';

///
/// This renderer fetches the desired bitmap from openstreetmap website. Since the bitmaps are 256 pixels in size the same size must be
/// configured in the displayModel.
///
class OsmOnlineRenderer extends Renderer {
  static final String uriPrefix = "https://a.tile.openstreetmap.org";

  OsmOnlineRenderer();

  @override
  Future<JobResult> executeJob(JobRequest job) async {
    // Global options
    final options = CacheOptions(
      // A default store is required for interceptor.
      store: MemCacheStore(),
    );

    // Add cache interceptor with global/default options
    final dio = Dio()..interceptors.add(DioCacheInterceptor(options: options));

    //Uri uri = Uri.parse("$uriPrefix/${job.tile.zoomLevel}/${job.tile.tileX}/${job.tile.tileY}.png");
    final response = await dio.get(
      "$uriPrefix/${job.tile.zoomLevel}/${job.tile.tileX}/${job.tile.tileY}.png",
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
        headers: {"User-Agent": "MapsforgeFlutter (https://pub.dev/packages/mapsforge_flutter)"},
      ),
    );

    var codec = await ui.instantiateImageCodec(response.data);
    // add additional checking for number of frames etc here
    var frame = await codec.getNextFrame();
    ui.Image img = frame.image;

    TilePicture result = TilePicture.fromBitmap(img);
    return JobResult.normal(result);
  }

  @override
  Future<JobResult> retrieveLabels(JobRequest job) {
    return Future.value(JobResult.unsupported());
  }

  @override
  String getRenderKey() {
    return "osm";
  }

  @override
  bool supportLabels() {
    return false;
  }
}
