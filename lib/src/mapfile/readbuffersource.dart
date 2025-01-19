import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart' as readbuffer;

/// an interface for fetching data from a mapfile. The idea is to gather the data either from a physical file or from a file already in memory.
abstract class ReadbufferSource {
  /// returns the length of the file. If needed this method may be removed but the length check must be done in the individual read-methods then.
  Future<int> length();

  /// closes the underlying file
  void close();

  /// Reads the given amount of bytes from the file into the read buffer and resets the internal buffer position. If
  /// the capacity of the read buffer is too small, a larger one is created automatically.
  ///
  /// @param length the amount of bytes to read from the file.
  /// @return true if the whole data was read successfully, false otherwise.
  /// @throws IOException if an error occurs while reading the file.
  Future<readbuffer.Readbuffer> readFromFile(
      {int? offset, required int length});

  /// Reads the bytes from the underlying file starting at [indexBlockPosition].
  Future<Uint8List> readDirect(int indexBlockPosition, int indexBlockSize);
}
