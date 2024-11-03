import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/layer/job/view_job_request.dart';

import '../graphics/tilebitmap.dart';
import '../layer/job/job.dart';
import '../layer/job/jobresult.dart';
import '../layer/job/view_job_result.dart';

abstract class ViewRenderer implements JobRenderer {
  Future<ViewJobResult> executeViewJob(ViewJobRequest viewJobRequest);

  @override
  Future<TileBitmap> createErrorBitmap(double tileSize, error) {
    // TODO: implement createErrorBitmap
    throw UnimplementedError();
  }

  @override
  Future<TileBitmap> createMissingBitmap(double tileSize) {
    // TODO: implement createMissingBitmap
    throw UnimplementedError();
  }

  @override
  Future<TileBitmap> createNoDataBitmap(double tileSize) {
    // TODO: implement createNoDataBitmap
    throw UnimplementedError();
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  Future<JobResult> executeJob(Job job) {
    // TODO: implement executeJob
    throw UnimplementedError();
  }

  @override
  Future<JobResult> retrieveLabels(Job job) {
    // TODO: implement retrieveLabels
    throw UnimplementedError();
  }
}
