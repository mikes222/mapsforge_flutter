import 'package:datastore_renderer/src/job/job_request.dart';
import 'package:datastore_renderer/src/job/job_result.dart';

///
/// This abstract class provides the foundation to render a bitmap for the given tile.
///
abstract class Renderer {
  void dispose() {}

  ///
  /// The rendering job to execute.
  ///
  /// @returns the tilebitmap or null if no data available for this tile
  /// @returns an exception e.g. if the server is not reachable
  ///
  Future<JobResult> executeJob(JobRequest jobRequest);

  /// For mapfiles we can either render everything into the images or render just the basic map and show the captions unrotated while rotating the map on screen.
  /// This method returns the captions to draw each time (maybe rotated)
  Future<JobResult> retrieveLabels(JobRequest jobRequest);

  /// Returns a key for the caches. In order to use different caches for different renderings the
  /// renderer can provide a unique key. The key should be the same if the rendering should provide the
  /// exact same image again. The key should be different if the renderer provides different images. This
  /// can be used for light/dark themes or for example when font sizes change.
  String getRenderKey();
}
