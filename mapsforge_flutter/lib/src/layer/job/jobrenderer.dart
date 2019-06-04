import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';

import 'job.dart';

abstract class JobRenderer {
  Future<TileBitmap> executeJob(Job job);
}
