import 'dart:typed_data';

/// Dynamic builder for constructing Uint8List with automatic capacity management.
///
/// This class provides an efficient way to build byte arrays when the final size
/// is unknown. It automatically grows the internal buffer as needed, doubling
/// capacity when more space is required.
///
/// Key features:
/// - Automatic buffer growth (starts at ~100KB)
/// - Efficient memory management with buffer doubling
/// - View-based data access (no unnecessary copying)
/// - Optimized for sequential byte appending
class Uint8ListBuilder {
  /// Initial buffer size (~100KB) for reasonable performance.
  static const int _kInitialSize = 2000;

  /// Current number of bytes stored in the buffer.
  int _usedLength = 0;

  /// Internal growable buffer for storing bytes.
  Uint8List _buffer = Uint8List(_kInitialSize);

  /// Returns a view of the currently stored data without copying.
  ///
  /// Creates a Uint8List view that references only the used portion
  /// of the internal buffer, avoiding unnecessary memory allocation.
  Uint8List get data => Uint8List.view(_buffer.buffer, 0, _usedLength);

  /// Returns a copy of the currently stored data and clears the buffer.
  Uint8List get dataAndClear {
    if (_usedLength == 0) return Uint8List(0);
    final Uint8List newBuffer = Uint8List(_usedLength);
    newBuffer.setAll(0, data);
    if (_usedLength > _kInitialSize) _buffer = Uint8List(_kInitialSize);
    _usedLength = 0;
    return newBuffer;
  }

  int get length => _usedLength;

  void clear() {
    _usedLength = 0;
    _buffer = Uint8List(_kInitialSize);
  }

  /// Appends bytes to the builder, growing the buffer if necessary.
  ///
  /// [bytes] The byte data to append to the builder
  void addAll(List<int> bytes) {
    _ensureCanAdd(bytes.length);
    _buffer.setAll(_usedLength, bytes);
    _usedLength += bytes.length;
  }

  void add(int byte) {
    _ensureCanAdd(1);
    _buffer[_usedLength] = byte;
    _usedLength += 1;
  }

  /// Ensures the buffer has sufficient capacity for additional bytes.
  ///
  /// Grows the buffer by doubling its size until it can accommodate
  /// the requested number of additional bytes.
  ///
  /// [byteCount] Number of additional bytes that need to be stored
  void _ensureCanAdd(int byteCount) {
    final int totalSpaceNeeded = _usedLength + byteCount;
    if (totalSpaceNeeded > 1000000) {
      print("Buffer more than 1MB: $totalSpaceNeeded");
      print(StackTrace.current);
    }

    int newLength = _buffer.length;
    while (totalSpaceNeeded > newLength) {
      if (newLength < _kInitialSize * 1024) {
        newLength *= 2;
      } else {
        newLength += _kInitialSize * 1024;
      }
    }

    if (newLength != _buffer.length) {
      final Uint8List newBuffer = Uint8List(newLength);
      newBuffer.setAll(0, _buffer);
      //newBuffer.setRange(0, _usedLength, _buffer);
      _buffer = newBuffer;
    }
  }
}
