import 'dart:convert';
import 'dart:typed_data';

import 'package:mapsforge_flutter_core/src/utils/uint8_list_builder.dart';

/// Web-compatible stub implementation of Writebuffer.
///
/// This implementation provides the same API as the IO version but throws
/// [UnsupportedError] for operations that require file system access,
/// which is not available on the web platform.
///
/// The web platform typically doesn't need mapfile writing capabilities,
/// as this is usually done on the server side or in development environments.
class Writebuffer {
  /// A chunk of data read from the underlying file
  final Uint8ListBuilder _bufferData = Uint8ListBuilder();

  int _bufferPosition = 0;

  void writeToSink(SinkWithCounter sink) {
    sink.add(_bufferData.data);
  }

  void _ensureBuffer() {
    if (_bufferData.length > 100 * 1024 * 1024) {
      print("Buffer more than 100MB: ${_bufferData.length}");
      print(StackTrace.current);
    }
  }

  void clear() {
    _bufferData.clear();
    _bufferPosition = 0;
  }

  void appendInt1(int value) {
    _bufferPosition += 1;
    _ensureBuffer();
    _bufferData.add(value & 0xff);
  }

  /// Converts four bytes from the read buffer to a signed int.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the int value.
  void appendInt2(int value) {
    _bufferPosition += 2;
    _ensureBuffer();
    if (value >= 0) {
      _bufferData.add((value >> 8) & 0x7f);
      _bufferData.add((value) & 0xff);
    } else {
      _bufferData.add((value >> 8) & 0xff);
      _bufferData.add((value) & 0xff);
    }
  }

  /// Converts four bytes from the read buffer to a signed int.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the int value.
  void appendUInt2(int value) {
    _bufferPosition += 2;
    _ensureBuffer();
    _bufferData.add((value >> 8) & 0xff);
    _bufferData.add((value) & 0xff);
  }

  /// Converts four bytes from the read buffer to a signed int.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the int value.
  void appendInt4(int value) {
    _bufferPosition += 4;
    _ensureBuffer();
    if (value >= 0) {
      _bufferData.add((value >> 24) & 0x7f);
      _bufferData.add((value >> 16) & 0xff);
      _bufferData.add((value >> 8) & 0xff);
      _bufferData.add((value) & 0xff);
    } else {
      _bufferData.add((value >> 24) & 0x7f | 0x80);
      _bufferData.add((value >> 16) & 0xff);
      _bufferData.add((value >> 8) & 0xff);
      _bufferData.add((value) & 0xff);
    }
  }

  /// Converts four bytes from the read buffer to a float.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the float value.
  void appendFloat4(double value) {
    // https://stackoverflow.com/questions/55355482/parsing-integer-bit-patterns-as-ieee-754-floats-in-dart
    // var bdata = ByteData(4);
    // bdata.setInt32(0, readInt());
    // return bdata.getFloat32(0);

    var bdata = ByteData(4);
    bdata.setFloat32(0, value);
    int result = bdata.getInt32(0);
    appendInt4(result);
  }

  void appendInt5(int value) {
    _bufferPosition += 5;
    _ensureBuffer();
    _bufferData.add((value >> 32) & 0xff);
    _bufferData.add((value >> 24) & 0xff);
    _bufferData.add((value >> 16) & 0xff);
    _bufferData.add((value >> 8) & 0xff);
    _bufferData.add((value) & 0xff);
  }

  /// Converts eight bytes from the read buffer to a signed int.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the int value.
  void appendInt8(int value) {
    _bufferPosition += 8;
    _ensureBuffer();
    if (value >= 0) {
      _bufferData.add((value >> 56) & 0x7f);
      _bufferData.add((value >> 48) & 0xff);
      _bufferData.add((value >> 40) & 0xff);
      _bufferData.add((value >> 32) & 0xff);
      _bufferData.add((value >> 24) & 0xff);
      _bufferData.add((value >> 16) & 0xff);
      _bufferData.add((value >> 8) & 0xff);
      _bufferData.add((value) & 0xff);
    } else {
      _bufferData.add((value >> 56) & 0x7f | 0x80);
      _bufferData.add((value >> 48) & 0xff);
      _bufferData.add((value >> 40) & 0xff);
      _bufferData.add((value >> 32) & 0xff);
      _bufferData.add((value >> 24) & 0xff);
      _bufferData.add((value >> 16) & 0xff);
      _bufferData.add((value >> 8) & 0xff);
      _bufferData.add((value) & 0xff);
    }
  }

  void appendUint8(List<int> values) {
    _bufferPosition += values.length;
    _ensureBuffer();
    _bufferData.addAll(values);
  }

  void appendString(String value) {
    var utf8List = utf8.encoder.convert(value);
    appendUnsignedInt(utf8List.length);
    _bufferPosition += utf8List.length;
    _ensureBuffer();
    _bufferData.addAll(utf8List);
  }

  void appendStringWithoutLength(String value) {
    var utf8List = utf8.encoder.convert(value);
    _bufferPosition += utf8List.length;
    _ensureBuffer();
    _bufferData.addAll(utf8List);
  }

  /// Converts an unsigned int to a variable amount of bytes
  /// The first bit of each byte is used for continuation info, the other seven bits for data.
  /// the value of the first bit is 1 if the following byte belongs to the field, 0 otherwise.
  /// each byte holds seven bits of the numeric value, starting with the least significant ones.
  void appendUnsignedInt(int value) {
    _bufferPosition += 10;
    _ensureBuffer();
    int realByteCount = 0;
    while (value > 0x7f) {
      _bufferData.add((value & 0x7f) | 0x80);
      value = value >> 7;
      ++realByteCount;
    }
    _bufferData.add(value);
    ++realByteCount;
    _bufferPosition -= (10 - realByteCount);
  }

  /// the first bit of each byte is used for continuation info, the other six (last byte) or seven (all other bytes) bits for data.
  /// the value of the first bit is 1 if the following byte belongs to the field, 0 otherwise.
  /// each byte holds six (last byte) or seven (all other bytes) bits of the numeric value, starting with the least significant ones.
  /// the second bit in the last byte indicates the sign of the number. A value of 0 means positive, 1 negative.
  /// numeric value is stored as magnitude for negative values (as opposed to two's complement).
  void appendSignedInt(int value) {
    _bufferPosition += 10;
    _ensureBuffer();
    int realByteCount = 0;
    int sign = 0;
    if (value < 0) {
      sign = 0x40;
      value = value * -1;
    }
    while (value > 0x3f) {
      _bufferData.add((value & 0x7f) | 0x80);
      value = value >> 7;
      ++realByteCount;
    }
    _bufferData.add(value | sign);
    ++realByteCount;
    _bufferPosition -= (10 - realByteCount);
  }

  void appendWritebuffer(Writebuffer other) {
    _bufferPosition += other._bufferPosition;
    _ensureBuffer();
    _bufferData.addAll(other._bufferData.data);
  }

  /// File operations are not supported on the web platform.
  ///
  /// Throws [UnsupportedError] as file system access is not available in web browsers.
  Future<void> writeIntoAt(int position, dynamic raf) async {
    throw UnsupportedError(
      'File operations are not supported on the web platform. '
      'Mapfile writing is typically done on the server side or in development environments.',
    );
  }

  int get length => _bufferData.length;

  Uint8List getUint8List() {
    return _bufferData.data;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Web-compatible stub implementation of SinkWithCounter.
///
/// This implementation provides the same API as the IO version but throws
/// [UnsupportedError] for operations that require file system access.
class SinkWithCounter {
  /// Placeholder for sink - not used on web platform
  final dynamic sink;

  int written = 0;

  SinkWithCounter(this.sink);

  /// File operations are not supported on the web platform.
  ///
  /// Throws [UnsupportedError] as file system access is not available in web browsers.
  Future<void> close() async {
    throw UnsupportedError(
      'File operations are not supported on the web platform. '
      'Mapfile writing is typically done on the server side or in development environments.',
    );
  }

  /// File operations are not supported on the web platform.
  ///
  /// Throws [UnsupportedError] as file system access is not available in web browsers.
  void add(List<int> buffer) {
    throw UnsupportedError(
      'File operations are not supported on the web platform. '
      'Mapfile writing is typically done on the server side or in development environments.',
    );
  }

  /// File operations are not supported on the web platform.
  ///
  /// Throws [UnsupportedError] as file system access is not available in web browsers.
  Future<void> flush() async {
    throw UnsupportedError(
      'File operations are not supported on the web platform. '
      'Mapfile writing is typically done on the server side or in development environments.',
    );
  }
}
