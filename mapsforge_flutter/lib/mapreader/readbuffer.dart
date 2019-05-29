import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../model/tag.dart';
import 'package:logging/logging.dart';

import '../parameters.dart';
import 'deserializer.dart';

/**
 * Reads from a {@link RandomAccessFile} into a buffer and decodes the data.
 */
class ReadBuffer {
  static final _log = new Logger('ReadBuffer');

  static final String CHARSET_UTF8 = "UTF-8";

  Uint8List bufferData;
  int bufferPosition;
  final RandomAccessFile inputChannel;

  final List<int> tagIds = new List();

  ReadBuffer(this.inputChannel) {}

  /**
   * Returns one signed byte from the read buffer.
   *
   * @return the byte value.
   */
  int readByte() {
    return this.bufferData[this.bufferPosition++];
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
    if (this.bufferData == null || this.bufferData.length < length) {
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
//    this.bufferWrapper = Uint8List(0).buffer; //.clear();

    bufferData = await this.inputChannel.read(length);
    assert(bufferData != null);
    assert(bufferData.length == length);
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
// ensure that the read buffer is large enough
    if (this.bufferData == null || this.bufferData.length < length) {
// ensure that the read buffer is not too large
      if (length > Parameters.MAXIMUM_BUFFER_SIZE) {
        _log.warning("invalid read length: $length");
        return false;
      }
      this.bufferData = Uint8List(length);
      //this.bufferWrapper = ByteBuffer.wrap(this.bufferData, 0, length);
    }

// reset the buffer position and read the data into the buffer
    this.bufferPosition = 0;

    //synchronized(this.inputChannel) {
    this.inputChannel.setPosition(offset);
//    return this.inputChannel.read(this.bufferWrapper) == length;
    bufferData = await this.inputChannel.read(length);
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
    this.bufferPosition += 4;
    return Deserializer.getInt(this.bufferData, this.bufferPosition - 4);
  }

  /**
   * Converts eight bytes from the read buffer to a signed long.
   * <p/>
   * The byte order is big-endian.
   *
   * @return the long value.
   */
  int readLong() {
    this.bufferPosition += 8;
    return Deserializer.getLong(this.bufferData, this.bufferPosition - 8);
  }

  /**
   * Converts two bytes from the read buffer to a signed int.
   * <p/>
   * The byte order is big-endian.
   *
   * @return the int value.
   */
  int readShort() {
    this.bufferPosition += 2;
    return Deserializer.getShort(this.bufferData, this.bufferPosition - 2);
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
    int variableByteDecode = 0;
    int variableByteShift = 0;

    // check if the continuation bit is set
    while ((this.bufferData[this.bufferPosition] & 0x80) != 0) {
      variableByteDecode |=
          (this.bufferData[this.bufferPosition++] & 0x7f) << variableByteShift;
      variableByteShift += 7;
    }

    // read the six data bits from the last byte
    if ((this.bufferData[this.bufferPosition] & 0x40) != 0) {
      // negative
      return -(variableByteDecode |
          ((this.bufferData[this.bufferPosition++] & 0x3f) <<
              variableByteShift));
    }
    // positive
    return variableByteDecode |
        ((this.bufferData[this.bufferPosition++] & 0x3f) << variableByteShift);
  }

  List<Tag> readTags(List<Tag> tagsArray, int numberOfTags) {
    List<Tag> tags = new List();
    tagIds.clear();

    int maxTag = tagsArray.length;

    for (int tagIndex = numberOfTags; tagIndex != 0; --tagIndex) {
      int tagId = readUnsignedInt();
      if (tagId < 0 || tagId >= maxTag) {
        _log.warning("invalid tag ID: $tagId");
        return null;
      }
      tagIds.add(tagId);
    }

    for (int tagId in tagIds) {
      Tag tag = tagsArray[tagId];
      // Decode variable values of tags
      if (tag.value.length == 2 && tag.value.startsWith('%')) {
        String value = tag.value;
        if (value.codeUnitAt(1) == 'b') {
          value = readByte().toString();
        } else if (value.codeUnitAt(1) == 'i') {
          if (tag.key.contains(":colour")) {
            value = "#" + readInt().toRadixString(16);
          } else {
            value = readInt().toString();
          }
        } else if (value.codeUnitAt(1) == 'f') {
          value = readFloat().toString();
        } else if (value.codeUnitAt(1) == 'h') {
          value = readShort().toString();
        } else if (value.codeUnitAt(1) == 's') {
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
    int variableByteDecode = 0;
    int variableByteShift = 0;

    // check if the continuation bit is set
    while ((this.bufferData[this.bufferPosition] & 0x80) != 0) {
      variableByteDecode |=
          (this.bufferData[this.bufferPosition++] & 0x7f) << variableByteShift;
      variableByteShift += 7;
    }

    // read the seven data bits from the last byte
    return variableByteDecode |
        (this.bufferData[this.bufferPosition++] << variableByteShift);
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
    assert(stringLength >= 0);
    if (stringLength > 0 &&
        this.bufferPosition + stringLength <= this.bufferData.length) {
      this.bufferPosition += stringLength;

      return utf8.decoder
          .convert(bufferData, bufferPosition - stringLength, bufferPosition);
    }
    return null;
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
    return this.bufferData.length;
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
