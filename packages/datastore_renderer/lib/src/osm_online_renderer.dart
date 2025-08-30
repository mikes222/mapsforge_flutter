import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:mapsforge_flutter_core/utils.dart';
import 'package:datastore_renderer/src/job/job_request.dart';
import 'package:datastore_renderer/src/job/job_result.dart';
import 'package:datastore_renderer/src/renderer.dart';
import 'package:datastore_renderer/src/ui/tile_picture.dart';
import 'package:http/http.dart';

///
/// This renderer fetches the desired bitmap from openstreetmap website. Since the bitmaps are 256 pixels in size the same size must be
/// configured in the displayModel.
///
class OsmOnlineRenderer extends Renderer {
  static final String uriPrefix = "https://a.tile.openstreetmap.org";

  OsmOnlineRenderer();

  @override
  Future<JobResult> executeJob(JobRequest job) async {
    Uri uri = Uri.parse("$uriPrefix/${job.tile.zoomLevel}/${job.tile.tileX}/${job.tile.tileY}.png");

    Request req = Request('GET', uri);
    StreamedResponse response = await req.send();

    final Uint8ListBuilder builder = await response.stream.fold(Uint8ListBuilder(), (Uint8ListBuilder buffer, List<int> bytes) => buffer..add(bytes));
    final Uint8List content = builder.data;

    var codec = await ui.instantiateImageCodec(content.buffer.asUint8List());
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
