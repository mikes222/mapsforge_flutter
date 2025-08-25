import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_common/src/buffer/deserializer.dart';
import 'package:logging/logging.dart';

import '../model/tag.dart';

/// A chunk of a file.
class Readbuffer {
  static final _log = new Logger('ReadBuffer');

  static final String CHARSET_UTF8 = "UTF-8";

  /// A chunk of data read from the underlying file
  final Uint8List _bufferData;

  /// The current offset in the underlying file which denotes the start of the [_bufferData] or [null] if unknown
  final int? _offset;

  /// The current position of the read pointer in the [_bufferData]. The position cannot exceed the amount of bytes in [_bufferData]
  int _bufferPosition;

  /// Shared ByteData instance to avoid allocations for float/int conversions
  final ByteData _sharedByteData = ByteData(8);

  /// Cached UTF-8 decoder to avoid repeated instantiation
  static final Utf8Decoder _utf8Decoder = const Utf8Decoder();

  ///
  /// Default constructor to open a buffer for reading a mapfile
  ///
  Readbuffer(this._bufferData, this._offset) : _bufferPosition = 0;

  /// Creates a new Readbuffer by copying the given buffer and setting the new buffer position to 0.
  Readbuffer.from(Readbuffer other) : _bufferData = other._bufferData, _offset = other._offset, _bufferPosition = 0;

  Uint8List getBuffer(int position, int length) {
    assert(position >= 0);
    assert(position + length <= _bufferData.length);
    return _bufferData.sublist(position, position + length);
  }

  /// Returns one signed byte from the read buffer.
  ///
  /// @return the byte value.
  int readByte() {
    int value = _bufferData[_bufferPosition++];
    // Convert unsigned byte to signed byte
    return value > 127 ? value - 256 : value;
  }

  /// Converts four bytes from the read buffer to a float.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the float value.
  double readFloat() {
    // https://stackoverflow.com/questions/55355482/parsing-integer-bit-patterns-as-ieee-754-floats-in-dart
    // Use a single ByteData view instead of creating new instances
    int intValue = readInt();
    _sharedByteData.setInt32(0, intValue, Endian.big);
    return _sharedByteData.getFloat32(0, Endian.big);
  }

  /// Converts four bytes from the read buffer to a signed int.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the int value.
  int readInt() {
    _bufferPosition += 4;
    return Deserializer.getInt(_bufferData, _bufferPosition - 4);
  }

  /// Converts eight bytes from the read buffer to a signed long.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the long value.
  int readLong() {
    _bufferPosition += 8;
    return Deserializer.getLong(_bufferData, _bufferPosition - 8);
  }

  /// Converts two bytes from the read buffer to a signed int.
  /// <p/>
  /// The byte order is big-endian.
  ///
  /// @return the int value.
  int readShort() {
    assert(_bufferPosition < _bufferData.length);
    this._bufferPosition += 2;
    return Deserializer.getShort(_bufferData, _bufferPosition - 2);
  }

  List<Tag> readTags(List<Tag> tagsArray, int numberOfTags) {
    List<Tag> tags = [];
    List<int> tagIds = [];

    int maxTag = tagsArray.length;

    for (int tagIndex = numberOfTags; tagIndex != 0; --tagIndex) {
      int tagId = readUnsignedInt();
      if (tagId < 0 || tagId >= maxTag) {
        _log.warning("invalid tag ID: $tagId for index $tagIndex, it should be between 0 and $maxTag, checked at offset $_offset + $_bufferPosition");
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
            value = "#${readInt().toRadixString(16)}";
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
    assert(_bufferPosition <= _bufferData.length);
    int variableByteDecode = 0;
    int variableByteShift = 0;

    // Optimized variable-length integer decoding with reduced array access
    int pos = _bufferPosition;
    final data = _bufferData;

    // Unroll first few iterations for common cases
    int byte = data[pos++];
    if ((byte & 0x80) == 0) {
      _bufferPosition = pos;
      return byte & 0x7f;
    }

    variableByteDecode = byte & 0x7f;
    variableByteShift = 7;

    byte = data[pos++];
    if ((byte & 0x80) == 0) {
      _bufferPosition = pos;
      return variableByteDecode | ((byte & 0x7f) << variableByteShift);
    }

    variableByteDecode |= (byte & 0x7f) << variableByteShift;
    variableByteShift += 7;

    // Continue with loop for longer values
    while ((data[pos] & 0x80) != 0) {
      variableByteDecode |= (data[pos] & 0x7f) << variableByteShift;
      variableByteShift += 7;
      ++pos;
    }

    // read the seven data bits from the last byte
    variableByteDecode |= (data[pos] & 0x7f) << variableByteShift;
    _bufferPosition = pos + 1;
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

    // Optimized signed variable-length integer decoding
    int pos = _bufferPosition;
    final data = _bufferData;

    // check if the continuation bit is set
    while ((data[pos] & 0x80) != 0) {
      variableByteDecode |= (data[pos] & 0x7f) << variableByteShift;
      variableByteShift += 7;
      ++pos;
    }

    variableByteDecode |= (data[pos] & 0x3f) << variableByteShift;

    // read the six data bits from the last byte
    if ((data[pos] & 0x40) != 0) {
      // negative
      _bufferPosition = pos + 1;
      return -variableByteDecode;
    }
    // positive
    _bufferPosition = pos + 1;
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
    assert(stringLength > 0);
    if (_bufferPosition + stringLength <= _bufferData.length) {
      int startPos = _bufferPosition;
      _bufferPosition += stringLength;
      //_log.info("Reading utf8 $stringLength bytes ending at $_bufferPosition");

      // Use cached decoder and avoid creating intermediate lists for small strings
      if (stringLength <= 64) {
        // For small strings, use sublist view which is more efficient
        String result = _utf8Decoder.convert(_bufferData.sublist(startPos, startPos + stringLength));
        //_log.info("String found $result");
        return result;
      } else {
        // For larger strings, use range conversion to avoid copying
        String result = _utf8Decoder.convert(_bufferData, startPos, startPos + stringLength);
        //_log.info("String found $result");
        return result;
      }
    }
    throw Exception("Cannot read utf8 string with $stringLength length at position $_bufferPosition of data with ${_bufferData.length} bytes");
  }

  /// @return the current buffer position.
  int getBufferPosition() {
    return _bufferPosition;
  }

  /// @return the current size of the read buffer.
  int getBufferSize() {
    return _bufferData.length;
  }

  /// Sets the buffer position to the given offset.
  ///
  /// @param bufferPosition the buffer position.
  void setBufferPosition(int bufferPosition) {
    // if (bufferPosition < 0 || bufferPosition >= _bufferData.length) {
    //   _log.warning("Cannot set bufferPosition $bufferPosition because we have only ${_bufferData.length} bytes available");
    // }
    assert(bufferPosition >= 0 && bufferPosition < _bufferData.length);
    _bufferPosition = bufferPosition;
  }

  /// Skips the given number of bytes in the read buffer.
  ///
  /// @param bytes the number of bytes to skip.
  void skipBytes(int bytes) {
    assert(_bufferPosition >= 0 && _bufferPosition + bytes <= _bufferData.length);
    _bufferPosition += bytes;
  }
}
