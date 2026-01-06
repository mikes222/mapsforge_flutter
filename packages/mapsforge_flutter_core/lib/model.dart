/// Core data models for geographic and map-related data structures.
///
/// This library provides fundamental classes for:
/// - Geographic coordinates (LatLong, ILatLong)
/// - Spatial boundaries (BoundingBox, MapRectangle)
/// - Map elements (Tile, Way, PointOfInterest)
/// - Geometric primitives (MapPoint, MapSize)
/// - Data organization (Tag, DatastoreBundle)
/// - Zoom level management (ZoomlevelRange)
/// - Coordinate utilities and transformations
library;

export 'src/model/boundingbox.dart';
export 'src/model/datastore.dart';
export 'src/model/datastore_bundle.dart';
export 'src/model/i_tag_collection.dart';
export 'src/model/ilatlong.dart';
export 'src/model/latlong.dart';
export 'src/model/mappoint.dart';
export 'src/model/mappoint_relative.dart';
export 'src/model/maprectangle.dart';
export 'src/model/mapsize.dart';
export 'src/model/micro_lat_long.dart';
export 'src/model/nano_lat_long.dart';
export 'src/model/pointofinterest.dart';
export 'src/model/tag.dart';
export 'src/model/tag_collection.dart';
export 'src/model/tile.dart';
export 'src/model/way.dart';
export 'src/model/waypath.dart';
export 'src/model/zoomlevel_range.dart';
