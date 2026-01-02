import 'package:mapsforge_flutter_core/src/buffer/readbuffer.dart';

/// An abstract interface for a source of binary data from which a `Readbuffer` can be created.
///
/// This class provides a common API for reading data from different sources, such
/// as a physical file or an in-memory byte array.
abstract class ReadbufferSource {
  /// Returns the total length of the data source in bytes.
  Future<int> length();

  /// Closes the underlying data source and releases any associated resources.
  void dispose();

  /// Frees resources that cannot be transferred to an isolate.
  ///
  /// This is typically called before sending the `ReadbufferSource` to another isolate.
  Future<void> freeRessources();

  /// Reads a block of data of the given [length] from the current position.
  ///
  /// Returns a `Readbuffer` containing the read data.
  Future<Readbuffer> readFromFile(int length);

  /// Reads a block of data of the given [length] from a specific [position].
  ///
  /// Returns a `Readbuffer` containing the read data.
  Future<Readbuffer> readFromFileAt(int position, int length);

  /// Returns the current read position in the data source.
  int getPosition();

  /// Sets the current read position in the data source.
  Future<void> setPosition(int position);

  /// Returns the content of the data source as a stream.
  Stream<List<int>> get inputStream;
}
