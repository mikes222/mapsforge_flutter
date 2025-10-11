/// The main library for the mapsforge_flutter_mapfile package.
///
/// This package provides the functionality to read and parse Mapsforge .map files,
/// which are a compact binary format for storing vector map data. It includes
/// classes for reading map file headers, index blocks, and tile data for ways,
/// points of interest (POIs), and labels.
///
/// This library exports the core `MapFile` class for interacting with map files,
/// as well as the `MapHeaderInfo` model class.
library;
export 'src/mapfile.dart';
export 'src/model/map_header_info.dart';
