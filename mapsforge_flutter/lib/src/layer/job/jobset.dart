import 'package:mapsforge_flutter/src/layer/job/job.dart';

///
/// A JobSet is a collection of one or more jobs which belongs together. When the map should be shown on screen,
/// the screen is split into Tiles and a job for each tile is created. All this jobs form a jobSet.
/// If the screen changes (move or zoom for example) a totally different jobset may be needed and the old jobset does not
/// need to be finished.
///
class JobSet {
  final List<Job> jobs = List();

  void add(Job job) {
    jobs.add(job);
  }
}
