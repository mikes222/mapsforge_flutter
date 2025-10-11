/// A library that provides utilities for filtering and processing way data from a map file.
///
/// This includes functionality for:
/// - Cropping ways to a given bounding box.
/// - Simplifying way geometries to reduce complexity.
/// - Filtering ways based on their size.
library;
export 'src/filter/way_cropper.dart';
export 'src/filter/way_simplify_filter.dart';
export 'src/filter/way_size_filter.dart';
