/// Map projection utilities for coordinate transformations.
/// 
/// This library provides:
/// - Mercator projection for converting lat/lng to screen coordinates
/// - Pixel projection for handling screen-space transformations
/// - Abstract projection interface for extensible coordinate systems
/// - Scale factor calculations for zoom level management
library;
export 'src/projection/mercator_projection.dart';
export 'src/projection/pixel_projection.dart';
export 'src/projection/projection.dart';
