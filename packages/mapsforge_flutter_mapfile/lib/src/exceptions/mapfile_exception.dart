/// An exception that is thrown when an error occurs during the processing of a
/// Mapsforge `.map` file.
///
/// This can happen if the file is corrupted, has an invalid format, or if an
/// unexpected I/O error occurs.
class MapFileException implements Exception {
  final String message;
  MapFileException(this.message);
}
