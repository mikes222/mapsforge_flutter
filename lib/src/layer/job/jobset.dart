import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';

import '../../../core.dart';
import '../../graphics/tilepicture.dart';
import '../../model/tile_dimension.dart';
import '../../rendertheme/renderinfo.dart';

///
/// A JobSet is a collection of one or more jobs which belongs together. When the map should be shown on screen,
/// the screen is split into Tiles and a job for each tile is created. All this jobs form a jobSet.
/// If the screen changes (move, zoom or changes its size) a totally different jobset may be needed and the old jobset does not
/// need to be finished.
///
class JobSet extends ChangeNotifier {
  /// true if we do not need this jobset anymore. Happens if we move the position before the jobset is completed.
  bool _disposed = false;

  /// The jobs to perform where we need images
  final List<Job> _renderJobs;

  /// The jobs where we need labels
  final List<Job> _labelJobs;

  /// The resulting bitmaps after the jobs has been processed.
  Map<Tile, JobResult> _bitmaps = {};

  /// All labels and rendering infos
  List<RenderInfo<Shape>> _renderInfos = [];

  List<Job> get renderJobs => _renderJobs;

  List<Job> get labelJobs => _labelJobs;

  List<RenderInfo>? get renderInfos => _renderInfos;

  final BoundingBox boundingBox;

  final TileDimension tileDimension;

  final int indoorLevel;

  final int zoomLevel;

  final Mappoint _center;

  JobSet({required this.boundingBox, required List<Job> jobs, required Mappoint center, required this.tileDimension})
      : assert(jobs.length > 0),
        _renderJobs = jobs,
        _labelJobs = List.from(jobs),
        indoorLevel = jobs.first.tile.indoorLevel,
        zoomLevel = jobs.first.tile.zoomLevel,
        _center = center;

  Mappoint getCenter() {
    return _center;
  }

  void labelJobFinished(Job job, List<RenderInfo> renderInfos) {
    if (_disposed) return;
    if (_labelJobs.contains(job)) {
      _renderInfos.addAll(renderInfos);
      _labelJobs.remove(job);
      notifyListeners();
    }
  }

  void labelJobsFinished(Map<Job, List<RenderInfo<Shape>>> items) {
    if (_disposed) return;
    items.forEach((job, renderInfos) {
      if (_labelJobs.contains(job)) {
        _renderInfos.addAll(renderInfos);
        _labelJobs.remove(job);
      }
    });
    notifyListeners();
  }

  void renderJobFinished(Job job, JobResult jobResult) {
    if (_disposed) return;
    _renderJobs.remove(job);
    //jobResult.bitmap?.incrementRefCount();
    TilePicture? old = _bitmaps[job.tile]?.picture;
    _bitmaps[job.tile] = jobResult;
    if (jobResult.renderInfos != null && _labelJobs.contains(job)) {
      _renderInfos.addAll(jobResult.renderInfos!);
      _labelJobs.remove(job);
    }
    //print("jobSet job finished ${_bitmaps!.length}");
    notifyListeners();
  }

  void renderJobFinishedPicture(Job job, TilePicture tilePicture) {
    if (_disposed) return;
    _renderJobs.remove(job);
    //jobResult.bitmap?.incrementRefCount();
    TilePicture? old = _bitmaps[job.tile]?.picture;
    if (old != null) {
      //old.decrementRefCount();
    }
    _bitmaps[job.tile] = JobResult(tilePicture, JOBRESULT.NORMAL);

    //print("jobSet job finished ${_bitmaps!.length}");
    notifyListeners();
  }

  void renderJobsFinishedPicture(Map<Job, TilePicture> jobResults) {
    if (_disposed) return;
    jobResults.forEach((Job job, TilePicture tilePicture) {
      _renderJobs.remove(job);
      TilePicture? old = _bitmaps[job.tile]?.picture;
      if (old != null) {
        //old.decrementRefCount();
      }
      _bitmaps[job.tile] = JobResult(tilePicture, JOBRESULT.NORMAL);
    });
    notifyListeners();
  }

  bool completed() {
    if (_disposed) return false;
    if (_renderJobs.isNotEmpty) return false;
    if (_labelJobs.isNotEmpty) return false;
    return true;
  }

  @mustCallSuper
  @override
  void dispose() {
    _disposed = true;
    _renderJobs.clear();
    _labelJobs.clear();
    _bitmaps.values.forEach((element) {
      //element.bitmap?.decrementRefCount();
    });
    _bitmaps.clear();
    super.dispose();
  }

  Map<Tile, JobResult> get bitmaps => _bitmaps;

  // void removeJobs() {
  //   _jobs.clear();
  //   _labelJobs.clear();
  //   _bitmaps.values.forEach((element) {
  //     //element.bitmap?.decrementRefCount();
  //   });
  //   _bitmaps.clear();
  // }

  @override
  String toString() {
    return 'JobSet{jobs: $_renderJobs, _bitmaps: $_bitmaps}';
  }

  /// https://stackoverflow.com/questions/63884633/unhandled-exception-a-changenotifier-was-used-after-being-disposed
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobSet &&
          runtimeType == other.runtimeType &&
          boundingBox == other.boundingBox &&
          indoorLevel == other.indoorLevel &&
          zoomLevel == other.zoomLevel;

  @override
  int get hashCode => boundingBox.hashCode ^ indoorLevel.hashCode;
}
