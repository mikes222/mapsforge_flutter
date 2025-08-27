import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_common/src/buffer/deserializer.dart';
import 'package:logging/logging.dart';

import '../model/tag.dart';

/// A high-performance buffer for reading binary data from Mapsforge files.
/// 
/// This class provides efficient methods for reading various data types from
/// binary streams, with optimizations for variable-length integer encoding
/// and UTF-8 string decoding commonly used in Mapsforge format.
/// 
/// Key features:
/// - Big-endian byte order for all multi-byte values
/// - Variable-length integer encoding support
/// - Optimized UTF-8 string decoding with caching
/// - Tag parsing for map metadata
/// - Memory-efficient buffer management
class Readbuffer {
  static final _log = Logger('ReadBuffer');

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

  /// Creates a new Readbuffer with the given data and optional file offset.
  /// 
  /// [_bufferData] The binary data to read from
  /// [_offset] The offset in the original file where this buffer starts (optional)
  Readbuffer(this._bufferData, this._offset) : _bufferPosition = 0;

  /// Creates a new Readbuffer by copying the given buffer and setting the new buffer position to 0.
  Readbuffer.from(Readbuffer other) : _bufferData = other._bufferData, _offset = other._offset, _bufferPosition = 0;

  /// Extracts a portion of the buffer as a new Uint8List.
  /// 
  /// [position] Starting position in the buffer
  /// [length] Number of bytes to extract
  /// Returns a sublist view of the buffer data
  Uint8List getBuffer(int position, int length) {
    assert(position >= 0);
    assert(position + length <= _bufferData.length);
    return _bufferData.sublist(position, position + length);
  }

  /// Reads one signed byte from the current buffer position.
  /// 
  /// Advances the buffer position by 1 byte.
  /// Returns the signed byte value (-128 to 127)
  int readByte() {
    int value = _bufferData[_bufferPosition++];
    // Convert unsigned byte to signed byte
    return value > 127 ? value - 256 : value;
  }

  /// Reads a 32-bit IEEE 754 float from the current buffer position.
  /// 
  /// Uses big-endian byte order. Advances the buffer position by 4 bytes.
  /// Returns the float value as a double
  double readFloat() {
    // https://stackoverflow.com/questions/55355482/parsing-integer-bit-patterns-as-ieee-754-floats-in-dart
    // Use a single ByteData view instead of creating new instances
    int intValue = readInt();
    _sharedByteData.setInt32(0, intValue, Endian.big);
    return _sharedByteData.getFloat32(0, Endian.big);
  }

  /// Reads a 32-bit signed integer from the current buffer position.
  /// 
  /// Uses big-endian byte order. Advances the buffer position by 4 bytes.
  /// Returns the signed integer value
  int readInt() {
    _bufferPosition += 4;
    return Deserializer.getInt(_bufferData, _bufferPosition - 4);
  }

  /// Reads a 64-bit signed integer from the current buffer position.
  /// 
  /// Uses big-endian byte order. Advances the buffer position by 8 bytes.
  /// Returns the signed long integer value
  int readLong() {
    _bufferPosition += 8;
    return Deserializer.getLong(_bufferData, _bufferPosition - 8);
  }

  /// Reads a 16-bit signed integer from the current buffer position.
  /// 
  /// Uses big-endian byte order. Advances the buffer position by 2 bytes.
  /// Returns the signed short integer value
  int readShort() {
    assert(_bufferPosition < _bufferData.length);
    this._bufferPosition += 2;
    return Deserializer.getShort(_bufferData, _bufferPosition - 2);
  }

  /// Reads and parses map tags from the buffer.
  /// 
  /// Tags can contain variable values that need to be decoded based on their type.
  /// Supported variable types: %b (byte), %i (int), %f (float), %h (short), %s (string)
  /// 
  /// [tagsArray] Array of available tag definitions
  /// [numberOfTags] Number of tags to read
  /// Returns a list of parsed Tag objects
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

  /// Reads a variable-length unsigned integer using LEB128 encoding.
  /// 
  /// The first bit of each byte indicates continuation (1) or termination (0).
  /// The remaining 7 bits contain data. This encoding is optimized for small values.
  /// 
  /// Returns the decoded unsigned integer value
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

  /// Reads a variable-length signed integer using modified LEB128 encoding.
  /// 
  /// Similar to unsigned variant, but the last byte uses 6 data bits and 1 sign bit.
  /// The sign bit (bit 6) in the final byte determines if the value is negative.
  /// 
  /// Returns the decoded signed integer value
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

  /// Reads a UTF-8 encoded string with variable length prefix.
  /// 
  /// First reads the string length as a variable-length unsigned integer,
  /// then decodes that many bytes as a UTF-8 string.
  /// 
  /// Returns the decoded string
  String readUTF8EncodedString() {
    return readUTF8EncodedString2(readUnsignedInt());
  }

  /// Reads a UTF-8 encoded string of specified length.
  /// 
  /// Uses optimized decoding strategies based on string length:
  /// - Small strings (≤64 bytes): Uses sublist for efficiency
  /// - Large strings: Uses range conversion to avoid copying
  /// 
  /// [stringLength] The number of bytes to read and decode
  /// Returns the decoded UTF-8 string
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

  /// Gets the current read position in the buffer.
  /// 
  /// Returns the byte offset from the start of the buffer
  int getBufferPosition() {
    return _bufferPosition;
  }

  /// Gets the total size of the buffer.
  /// 
  /// Returns the number of bytes in the buffer
  int getBufferSize() {
    return _bufferData.length;
  }

  /// Sets the current read position in the buffer.
  /// 
  /// [bufferPosition] The new position (must be within buffer bounds)
  void setBufferPosition(int bufferPosition) {
    // if (bufferPosition < 0 || bufferPosition >= _bufferData.length) {
    //   _log.warning("Cannot set bufferPosition $bufferPosition because we have only ${_bufferData.length} bytes available");
    // }
    assert(bufferPosition >= 0 && bufferPosition < _bufferData.length);
    _bufferPosition = bufferPosition;
  }

  /// Advances the buffer position by the specified number of bytes.
  /// 
  /// [bytes] The number of bytes to skip (must not exceed buffer bounds)
  void skipBytes(int bytes) {
    assert(_bufferPosition >= 0 && _bufferPosition + bytes <= _bufferData.length);
    _bufferPosition += bytes;
  }
}
