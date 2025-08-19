import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dart_common/utils.dart';
import 'package:datastore_renderer/src/job/job_request.dart';
import 'package:datastore_renderer/src/job/job_result.dart';
import 'package:datastore_renderer/src/model/tile_picture.dart';
import 'package:datastore_renderer/src/renderer.dart';
import 'package:http/http.dart';

///
/// This renderer fetches the desired bitmap from ArcGIS website. Since the bitmaps are 256 pixels in size the same size must be
/// configured in the displayModel.
///
/// Example:
/// ```
/// https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/17/43959/70254.jpg
/// ```
///
class ArcgisOnlineRenderer extends Renderer {
  static final String uriPrefix = "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile";

  ArcgisOnlineRenderer() {}

  @override
  Future<JobResult> executeJob(JobRequest job) async {
    Uri uri = Uri.parse("$uriPrefix/${job.tile.zoomLevel}/${job.tile.tileY}/${job.tile.tileX}.png");
    Request req = Request('GET', uri);
    final response = await req.send();

    final Uint8ListBuilder builder = await response.stream.fold(Uint8ListBuilder(), (Uint8ListBuilder buffer, List<int> bytes) => buffer..add(bytes));
    final Uint8List content = builder.data;

    var codec = await ui.instantiateImageCodec(content.buffer.asUint8List());
    // add additional checking for number of frames etc here
    var frame = await codec.getNextFrame();
    ui.Image img = frame.image;

    return JobResult.normal(TilePicture.fromBitmap(img));
  }

  @override
  String getRenderKey() {
    return "arcgis";
  }

  @override
  Future<JobResult> retrieveLabels(JobRequest job) {
    return Future.value(JobResult.unsupported());
  }
}

/////////////////////////////////////////////////////////////////////////////
