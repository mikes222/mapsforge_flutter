import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../datastore/deserializer.dart';
import '../model/tag.dart';

/// A portion of a mapfile
class Readbuffer {
  static final _log = new Logger('ReadBuffer');

  static final String CHARSET_UTF8 = "UTF-8";

  /// A chunk of data read from the underlying file
  final Uint8List _bufferData;

  /// The current offset in the underlying file which denotes the start of the [_bufferData] or [null] if unknown
  final int? _offset;

  /// The current position of the read pointer in the [_bufferData]. The position cannot exceed the amount of bytes in [_bufferData]
  int bufferPosition;

  ///
  /// Default constructor to open a buffer for reading a mapfile
  ///
  Readbuffer(this._bufferData, this._offset) : bufferPosition = 0;

  Readbuffer.from(Readbuffer other)
      : _bufferData = other._bufferData,
        _offset = other._offset,
        bufferPosition = 0;

  Uint8List getBuffer(int position, int length) {
    assert(position >= 0);
    assert(position + length <= _bufferData.length);
    return _bufferData.sublist(position, position + length);
  }

  /// Returns one signed byte from the read buffer.
  ///
  /// @return the byte value.
  int readByte() {
    ByteData bdata = ByteData(1);
    bdata.setInt8(0, this._bufferData[this.bufferPosition++]);
    return bdata.getInt8(0);
  }

  /// Converts four bytes from the read buffer to a float.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the float value.
  double readFloat() {
    // https://stackoverflow.com/questions/55355482/parsing-integer-bit-patterns-as-ieee-754-floats-in-dart
    var bdata = ByteData(4);
    bdata.setInt32(0, readInt());
    return bdata.getFloat32(0);
  }

  /// Converts four bytes from the read buffer to a signed int.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the int value.
  int readInt() {
    this.bufferPosition += 4;
    return Deserializer.getInt(this._bufferData, this.bufferPosition - 4);
  }

  /// Converts eight bytes from the read buffer to a signed long.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the long value.
  int readLong() {
    this.bufferPosition += 8;
    return Deserializer.getLong(this._bufferData, this.bufferPosition - 8);
  }

  /// Converts two bytes from the read buffer to a signed int.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the int value.
  int readShort() {
    assert(bufferPosition < _bufferData.length);
    this.bufferPosition += 2;
    return Deserializer.getShort(this._bufferData, this.bufferPosition - 2);
  }

  List<Tag> readTags(List<Tag> tagsArray, int numberOfTags) {
    List<Tag> tags = [];
    List<int> tagIds = [];

    int maxTag = tagsArray.length;

    for (int tagIndex = numberOfTags; tagIndex != 0; --tagIndex) {
      int tagId = readUnsignedInt();
      if (tagId < 0 || tagId >= maxTag) {
        _log.warning(
            "invalid tag ID: $tagId for index $tagIndex, it should be between 0 and $maxTag, checked at offset $_offset + $bufferPosition");
        //return null;
      } else {
        tagIds.add(tagId);
      }
    }

    for (int tagId in tagIds) {
      Tag tag = tagsArray[tagId];
      // Decode variable values of tags
      if (tag.value!.length == 2 && tag.value!.startsWith('%')) {
        String? value = tag.value;
        if (value == '%b') {
          value = readByte().toString();
        } else if (value == '%i') {
          if (tag.key!.contains(":colour")) {
            value = "#" + readInt().toRadixString(16);
          } else {
            value = readInt().toString();
          }
        } else if (value == '%f') {
          // TODO: read float to double leads to precision errors even when using .toStringAsPrecision(6);
          value = readFloat().toString();
        } else if (value == '%h') {
          value = readShort().toString();
        } else if (value == '%s') {
          value = readUTF8EncodedString();
        }
        tag = new Tag(tag.key, value);
      }
      tags.add(tag);
    }

    return tags;
  }

  /// Converts a variable amount of bytes from the read buffer to an unsigned int.
  /// <p/>
  /// The first bit is for continuation info, the other seven bits are for data.
  ///
  /// @return the int value.
  int readUnsignedInt() {
    assert(bufferPosition <= _bufferData.length);
    int variableByteDecode = 0;
    int variableByteShift = 0;

    // check if the continuation bit is set
    while ((this._bufferData[this.bufferPosition] & 0x80) != 0) {
      variableByteDecode |=
          (this._bufferData[this.bufferPosition] & 0x7f) << variableByteShift;
      variableByteShift += 7;
      ++bufferPosition;
    }

    // read the seven data bits from the last byte
    variableByteDecode |=
        (this._bufferData[this.bufferPosition] & 0x7f) << variableByteShift;
    variableByteShift += 7;
    ++bufferPosition;
    return variableByteDecode;
  }

  /// Converts a variable amount of bytes from the read buffer to a signed int.
  /// <p/>
  /// The first bit is for continuation info, the other six (last byte) or seven (all other bytes) bits are for data.
  /// The second bit in the last byte indicates the sign of the number.
  ///
  /// @return the int value.
  int readSignedInt() {
    int variableByteDecode = 0;
    int variableByteShift = 0;

    // check if the continuation bit is set
    while ((this._bufferData[this.bufferPosition] & 0x80) != 0) {
      variableByteDecode |=
          (this._bufferData[this.bufferPosition] & 0x7f) << variableByteShift;
      variableByteShift += 7;
      ++bufferPosition;
    }

    variableByteDecode |=
        (this._bufferData[this.bufferPosition] & 0x3f) << variableByteShift;
    variableByteShift += 6;

    // read the six data bits from the last byte
    if ((this._bufferData[this.bufferPosition] & 0x40) != 0) {
      // negative
      ++bufferPosition;
      return -1 * variableByteDecode;
    }
    // positive
    ++bufferPosition;
    return variableByteDecode;
  }

  /// Decodes a variable amount of bytes from the read buffer to a string.
  ///
  /// @return the UTF-8 decoded string (may be null).
  String readUTF8EncodedString() {
    return readUTF8EncodedString2(readUnsignedInt());
  }

  /// Decodes the given amount of bytes from the read buffer to a string.
  ///
  /// @param stringLength the length of the string in bytes.
  /// @return the UTF-8 decoded string (may be null).
  String readUTF8EncodedString2(int stringLength) {
    assert(stringLength >= 0);
    if (stringLength > 0 &&
        this.bufferPosition + stringLength <= this._bufferData.length) {
      this.bufferPosition += stringLength;
      //_log.info("Reading utf8 $stringLength bytes");
      String result = utf8.decoder
          .convert(_bufferData, bufferPosition - stringLength, bufferPosition);
      //_log.info("String found $result");
      return result;
    }
    throw Exception(
        "Cannot read utf8 string with $stringLength length at position $bufferPosition of data with ${_bufferData.length} bytes");
  }

  /// @return the current buffer position.
  int getBufferPosition() {
    return this.bufferPosition;
  }

  /// @return the current size of the read buffer.
  int getBufferSize() {
    return this._bufferData.length;
  }

  /// Sets the buffer position to the given offset.
  ///
  /// @param bufferPosition the buffer position.
  void setBufferPosition(int bufferPosition) {
    // if (bufferPosition < 0 || bufferPosition >= _bufferData.length) {
    //   _log.warning("Cannot set bufferPosition $bufferPosition because we have only ${_bufferData.length} bytes available");
    // }
    assert(bufferPosition >= 0 && bufferPosition < _bufferData.length);
    this.bufferPosition = bufferPosition;
  }

  /// Skips the given number of bytes in the read buffer.
  ///
  /// @param bytes the number of bytes to skip.
  void skipBytes(int bytes) {
    assert(bufferPosition >= 0 && bufferPosition + bytes <= _bufferData.length);
    this.bufferPosition += bytes;
  }
}
