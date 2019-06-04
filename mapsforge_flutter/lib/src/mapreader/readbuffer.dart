import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/parameters.dart';
import 'package:synchronized/synchronized.dart';

import '../model/tag.dart';
import 'deserializer.dart';

/// Reads from a {@link RandomAccessFile} into a buffer and decodes the data.
class ReadBuffer {
  static final _log = new Logger('ReadBuffer');

  static final String CHARSET_UTF8 = "UTF-8";

  static final Lock _lock = Lock();

  Uint8List _bufferData;
  int _offset;
  int bufferPosition;
  final RandomAccessFile inputChannel;

  ReadBuffer(this.inputChannel) {}

  Future<Uint8List> readDirect(int indexBlockPosition, int indexBlockSize) async {
    Uint8List result;
    await _lock.synchronized(() async {
      RandomAccessFile newInstance = await inputChannel.setPosition(indexBlockPosition);
      result = await (newInstance.read(indexBlockSize));
    });
    assert(result.length == indexBlockSize);
    return result;
  }

  Uint8List getBuffer(int position, int length) {
    return _bufferData.sublist(position, position + length);
  }

  /// Returns one signed byte from the read buffer.
  ///
  /// @return the byte value.
  int readByte() {
    assert(_bufferData != null);
    return this._bufferData[this.bufferPosition++];
  }

  /**
   * Converts four bytes from the read buffer to a float.
   * <p/>
   * The byte order is big-endian.
   *
   * @return the float value.
   */
  double readFloat() {
    // https://stackoverflow.com/questions/55355482/parsing-integer-bit-patterns-as-ieee-754-floats-in-dart
    var bdata = ByteData(4);
    bdata.setInt32(0, readInt());
    return bdata.getFloat32(0);
  }

  /**
   * Reads the given amount of bytes from the file into the read buffer and resets the internal buffer position. If
   * the capacity of the read buffer is too small, a larger one is created automatically.
   *
   * @param length the amount of bytes to read from the file.
   * @return true if the whole data was read successfully, false otherwise.
   * @throws IOException if an error occurs while reading the file.
   */
  Future<bool> readFromFile(int length) async {
    // ensure that the read buffer is large enough
    if (this._bufferData == null || this._bufferData.length < length) {
      // ensure that the read buffer is not too large
      if (length > Parameters.MAXIMUM_BUFFER_SIZE) {
        _log.warning("invalid read length: $length");
        return false;
      }
      //this.bufferData = Uint8List(length);
      //this.bufferWrapper = ByteBuffer.wrap(this.bufferData, 0, length);
    }

    // reset the buffer position and read the data into the buffer
    this.bufferPosition = 0;
    this._offset = 0;
//    this.bufferWrapper = Uint8List(0).buffer; //.clear();

    await _lock.synchronized(() async {
      _bufferData = await this.inputChannel.read(length);
    });
    assert(_bufferData != null);
    assert(_bufferData.length == length);
    return true;
  }

  /**
   * Reads the given amount of bytes from the file into the read buffer and resets the internal buffer position. If
   * the capacity of the read buffer is too small, a larger one is created automatically.
   *
   * @param offset the offset position, measured in bytes from the beginning of the file, at which to set the file pointer.
   * @param length the amount of bytes to read from the file.
   * @return true if the whole data was read successfully, false otherwise.
   * @throws IOException if an error occurs while reading the file.
   */
  Future<bool> readFromFile2(int offset, int length) async {
    assert(offset >= 0);
    if (length > Parameters.MAXIMUM_BUFFER_SIZE) {
      _log.warning("invalid read length: $length");
      return false;
    }

    await _lock.synchronized(() async {
      RandomAccessFile newInstance = await this.inputChannel.setPosition(offset);
      _bufferData = await newInstance.read(length);
// reset the buffer position and read the data into the buffer
      this.bufferPosition = 0;
      this._offset = offset;
    });
    assert(_bufferData != null);
    assert(_bufferData.length == length);
    return true;
    //}
  }

  /**
   * Converts four bytes from the read buffer to a signed int.
   * <p/>
   * The byte order is big-endian.
   *
   * @return the int value.
   */
  int readInt() {
    assert(_bufferData != null);
    this.bufferPosition += 4;
    return Deserializer.getInt(this._bufferData, this.bufferPosition - 4);
  }

  /**
   * Converts eight bytes from the read buffer to a signed long.
   * <p/>
   * The byte order is big-endian.
   *
   * @return the long value.
   */
  int readLong() {
    assert(_bufferData != null);
    this.bufferPosition += 8;
    return Deserializer.getLong(this._bufferData, this.bufferPosition - 8);
  }

  /**
   * Converts two bytes from the read buffer to a signed int.
   * <p/>
   * The byte order is big-endian.
   *
   * @return the int value.
   */
  int readShort() {
    assert(_bufferData != null);
    assert(bufferPosition < _bufferData.length);
    this.bufferPosition += 2;
    return Deserializer.getShort(this._bufferData, this.bufferPosition - 2);
  }

  List<Tag> readTags(List<Tag> tagsArray, int numberOfTags) {
    List<Tag> tags = new List();
    List<int> tagIds = new List();

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
      if (tag.value.length == 2 && tag.value.startsWith('%')) {
        String value = tag.value;
        if (value == '%b') {
          value = readByte().toString();
        } else if (value == '%i') {
          if (tag.key.contains(":colour")) {
            value = "#" + readInt().toRadixString(16);
          } else {
            value = readInt().toString();
          }
        } else if (value == '%f') {
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

  /**
   * Converts a variable amount of bytes from the read buffer to an unsigned int.
   * <p/>
   * The first bit is for continuation info, the other seven bits are for data.
   *
   * @return the int value.
   */
  int readUnsignedInt() {
    assert(_bufferData != null);
    assert(bufferPosition <= _bufferData.length);
    int variableByteDecode = 0;
    int variableByteShift = 0;

    // check if the continuation bit is set
    while ((this._bufferData[this.bufferPosition] & 0x80) != 0) {
      variableByteDecode |= (this._bufferData[this.bufferPosition] & 0x7f) << variableByteShift;
      variableByteShift += 7;
      ++bufferPosition;
    }

    // read the seven data bits from the last byte
    variableByteDecode |= (this._bufferData[this.bufferPosition] & 0x7f) << variableByteShift;
    variableByteShift += 7;
    ++bufferPosition;
    return variableByteDecode;
  }

  /**
   * Converts a variable amount of bytes from the read buffer to a signed int.
   * <p/>
   * The first bit is for continuation info, the other six (last byte) or seven (all other bytes) bits are for data.
   * The second bit in the last byte indicates the sign of the number.
   *
   * @return the int value.
   */
  int readSignedInt() {
    assert(_bufferData != null);
    int variableByteDecode = 0;
    int variableByteShift = 0;

    // check if the continuation bit is set
    while ((this._bufferData[this.bufferPosition] & 0x80) != 0) {
      variableByteDecode |= (this._bufferData[this.bufferPosition] & 0x7f) << variableByteShift;
      variableByteShift += 7;
      ++bufferPosition;
    }

    variableByteDecode |= (this._bufferData[this.bufferPosition] & 0x3f) << variableByteShift;
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

  /**
   * Decodes a variable amount of bytes from the read buffer to a string.
   *
   * @return the UTF-8 decoded string (may be null).
   */
  String readUTF8EncodedString() {
    return readUTF8EncodedString2(readUnsignedInt());
  }

  /**
   * Decodes the given amount of bytes from the read buffer to a string.
   *
   * @param stringLength the length of the string in bytes.
   * @return the UTF-8 decoded string (may be null).
   */
  String readUTF8EncodedString2(int stringLength) {
    assert(_bufferData != null);
    assert(stringLength >= 0);
    if (stringLength > 0 && this.bufferPosition + stringLength <= this._bufferData.length) {
      this.bufferPosition += stringLength;
      //_log.info("Reading utf8 $stringLength bytes");
      String result = utf8.decoder.convert(_bufferData, bufferPosition - stringLength, bufferPosition);
      //_log.info("String found $result");
      return result;
    }
    throw Exception(
        "Cannot read utf8 string with $stringLength length at position $bufferPosition of data with ${_bufferData.length} bytes");
  }

  /**
   * @return the current buffer position.
   */
  int getBufferPosition() {
    return this.bufferPosition;
  }

  /**
   * @return the current size of the read buffer.
   */
  int getBufferSize() {
    assert(_bufferData != null);
    return this._bufferData.length;
  }

  /**
   * Sets the buffer position to the given offset.
   *
   * @param bufferPosition the buffer position.
   */
  void setBufferPosition(int bufferPosition) {
    this.bufferPosition = bufferPosition;
  }

  /**
   * Skips the given number of bytes in the read buffer.
   *
   * @param bytes the number of bytes to skip.
   */
  void skipBytes(int bytes) {
    this.bufferPosition += bytes;
  }
}
