import 'package:mapsforge_flutter/graphics/tilebitmap.dart';

import 'job.dart';

abstract class JobRenderer {
  Future<TileBitmap> executeJob(Job job);
}
