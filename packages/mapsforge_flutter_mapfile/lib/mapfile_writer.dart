/// A library for writing and creating Mapsforge `.map` files.
///
/// This is intended for advanced use cases where you need to generate your own
/// map files from other data sources. It provides the tools to construct the
/// header, index, and data blocks required for a valid .map file.
///
/// It exports:
/// - `MapfileWriter`: The main class for orchestrating the map file creation process.
/// - `SubfileCreator`: A helper for creating the various sub-files within a .map file.
/// - `SubfileFiller`: A helper for populating the sub-files with data.
/// - `WayHolder`: A data holder for way information during the writing process.
export 'src/mapfile.dart';
export 'src/model/map_header_info.dart';
export 'src/writer/mapfile_writer.dart';
export 'src/writer/subfile_creator.dart';
export 'src/writer/subfile_filler.dart';
export 'src/writer/wayholder.dart';
