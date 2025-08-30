import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class Writebuffer {
  static final int ENHANCE_BUFFER_BYTES = 10000;

  /// A chunk of data read from the underlying file
  List<int> _bufferData = [];

  int _bufferPosition = 0;

  int _bufferLength = ENHANCE_BUFFER_BYTES;

  void writeToSink(SinkWithCounter sink) {
    sink.add(_bufferData);
  }

  void _ensureBuffer() {
    if (_bufferLength > _bufferPosition) return;
    _bufferLength = _bufferPosition + ENHANCE_BUFFER_BYTES;
//    Uint8List temp = Uint8List(_bufferLength);
//    temp.addAll(_bufferData);
//    _bufferData = temp;
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
    this._bufferPosition += 2;
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
    this._bufferPosition += 2;
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
    this._bufferPosition += 4;
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
    this._bufferPosition += 5;
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
    this._bufferPosition += 8;
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
    _bufferData.addAll(other._bufferData);
  }

  Future<void> writeIntoAt(int position, RandomAccessFile raf) async {
    await raf.setPosition(position);
    await raf.writeFrom(_bufferData);
  }

  int get length => _bufferData.length;

  Uint8List getUint8List() {
    return Uint8List.fromList(_bufferData);
  }
}

//////////////////////////////////////////////////////////////////////////////

class SinkWithCounter {
  final IOSink sink;

  int written = 0;

  SinkWithCounter(this.sink);

  Future<void> close() async {
    await sink.close();
  }

  void add(List<int> buffer) {
    sink.add(buffer);
    written += buffer.length;
  }

  Future<void> flush() async {
    return sink.flush();
  }
}
