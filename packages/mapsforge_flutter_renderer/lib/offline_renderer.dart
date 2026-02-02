/// Core rendering engine library for datastore-based map rendering.
///
/// This library provides the main rendering implementations for converting
/// map data from datastores into visual representations. It includes support
/// for various data sources and rendering strategies.
///
/// Key exports:
/// - **DatastoreRenderer**: Main renderer for local map data
/// - **ArcGISOnlineRenderer**: Renderer for ArcGIS online tile services
/// - **OSMOnlineRenderer**: Renderer for OpenStreetMap tile services
/// - **JobRequest/JobResult**: Asynchronous rendering job management
/// - **UIRenderContext**: Rendering context and state management
/// - **ImageHelper**: Utilities for image processing and manipulation
library;

export 'src/datastore_renderer.dart';
export 'src/dummy_renderer.dart';
export 'src/hgt/hgt_file_provider.dart';
export 'src/hgt/hgt_provider.dart';
export 'src/hgt/hgt_renderer.dart';
export 'src/hgt/hgt_tile_color_renderer.dart';
export 'src/hgt/hgt_tile_grey_renderer.dart';
export 'src/hgt/hgt_tile_hillshading_renderer.dart';
export 'src/hgt/hgt_tile_renderer.dart';
export 'src/hgt/noaa_file_provider.dart';
export 'src/job/job_request.dart';
export 'src/job/job_result.dart';
export 'src/memory_datastore.dart';
export 'src/multimap_datastore.dart';
export 'src/renderer.dart';
export 'src/util/image_helper.dart';
