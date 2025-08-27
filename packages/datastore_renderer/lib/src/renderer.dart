import 'package:datastore_renderer/src/job/job_request.dart';
import 'package:datastore_renderer/src/job/job_result.dart';

/// Abstract base class for tile rendering implementations.
/// 
/// This class defines the contract for rendering map tiles from various data sources.
/// Implementations handle specific data sources (local files, online services) and
/// provide both tile rendering and label extraction capabilities.
/// 
/// Key responsibilities:
/// - Execute rendering jobs to generate tile bitmaps
/// - Extract labels for separate rendering (rotation support)
/// - Provide cache keys for optimization
/// - Manage renderer lifecycle and resources
abstract class Renderer {
  /// Disposes of renderer resources and cleans up.
  /// 
  /// Called when the renderer is no longer needed to free up resources
  /// such as caches, network connections, or file handles.
  void dispose() {}

  /// Executes a rendering job to generate a tile bitmap.
  /// 
  /// Processes the job request and generates the corresponding tile image
  /// based on the renderer's data source and configuration.
  /// 
  /// [jobRequest] Request containing tile coordinates and rendering parameters
  /// Returns JobResult with tile bitmap or null if no data available
  /// Throws exception if rendering fails (e.g., server unreachable)
  Future<JobResult> executeJob(JobRequest jobRequest);

  /// Retrieves labels for separate rendering to support map rotation.
  /// 
  /// For rotation-enabled maps, labels are rendered separately from the base
  /// map to prevent text distortion. This method extracts label information
  /// that can be rendered dynamically with proper orientation.
  /// 
  /// [jobRequest] Request containing tile coordinates and rendering parameters
  /// Returns JobResult with label rendering instructions
  Future<JobResult> retrieveLabels(JobRequest jobRequest);

  /// Returns a unique cache key for this renderer configuration.
  /// 
  /// The cache key identifies the renderer's current configuration to enable
  /// proper cache separation. Keys should be identical for configurations that
  /// produce the same output and different for configurations that produce
  /// different results (e.g., different themes, font sizes, or data sources).
  /// 
  /// Returns unique string identifier for cache management
  String getRenderKey();

  /// Returns whether this renderer supports separate label rendering.
  /// 
  /// Indicates if the renderer can extract labels separately from the base
  /// map rendering, which is required for rotation support.
  /// 
  /// Returns true if separate label rendering is supported
  bool supportLabels();
}
