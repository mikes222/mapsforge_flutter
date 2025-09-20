import 'dart:typed_data';

/// A utility class to convert byte arrays to numbers.
class Deserializer {
  /// Converts five bytes of a byte array to a 40-bit integer.
  ///
  /// The byte order is big-endian.
  static int getFiveBytesLong(List<int> buffer, int offset) {
    return (buffer[offset] & 0xff) << 32 |
        (buffer[offset + 1] & 0xff) << 24 |
        (buffer[offset + 2] & 0xff) << 16 |
        (buffer[offset + 3] & 0xff) << 8 |
        (buffer[offset + 4] & 0xff);
  }

  /// Converts four bytes of a byte array to a signed 32-bit integer.
  ///
  /// The byte order is big-endian.
  static int getInt(Uint8List buffer, int offset) {
    assert(buffer.length >= offset + 4);
    if (buffer[offset] & 0x80 > 0) {
      return -1 *
          (((buffer[offset] & 0x7f) ^ 0x7f) << 24 |
              ((buffer[offset + 1] & 0xff) ^ 0xff) << 16 |
              ((buffer[offset + 2] & 0xff) ^ 0xff) << 8 |
              ((buffer[offset + 3] & 0xff) ^ 0xff) + 1);
    }
    return (buffer[offset] & 0x7f) << 24 | (buffer[offset + 1] & 0xff) << 16 | (buffer[offset + 2] & 0xff) << 8 | (buffer[offset + 3] & 0xff);
  }

  /// Converts eight bytes of a byte array to a signed 64-bit integer.
  ///
  /// The byte order is big-endian.
  static int getLong(Uint8List buffer, int offset) {
    assert(buffer.length >= offset + 8);
    // https://stackoverflow.com/questions/337355/javascript-bitwise-shift-of-long-long-number
    int part1 = (buffer[offset] & 0xff) << 24 | (buffer[offset + 1] & 0xff) << 16 | (buffer[offset + 2] & 0xff) << 8 | (buffer[offset + 3] & 0xff);
    int part2 = (buffer[offset + 4] & 0xff) << 24 | (buffer[offset + 5] & 0xff) << 16 | (buffer[offset + 6] & 0xff) << 8 | (buffer[offset + 7] & 0xff);
    if (buffer[offset] & 0x80 > 0) {
      return -1 * ((part1 * 256 * 256 * 256 * 256) + part2);
    }

    return (part1 * 256 * 256 * 256 * 256) + part2;
    // web platform cannot handle large bitshifts (more than 52 bit)
    // return (buffer[offset] & 0xff) << 56 |
    //     (buffer[offset + 1] & 0xff) << 48 |
    //     (buffer[offset + 2] & 0xff) << 40 |
    //     (buffer[offset + 3] & 0xff) << 32 |
    //     (buffer[offset + 4] & 0xff) << 24 |
    //     (buffer[offset + 5] & 0xff) << 16 |
    //     (buffer[offset + 6] & 0xff) << 8 |
    //     (buffer[offset + 7] & 0xff);
  }

  /// Converts two bytes of a byte array to a signed 16-bit integer.
  ///
  /// The byte order is big-endian.
  static int getShort(Uint8List buffer, int offset) {
    assert(buffer.length >= offset + 2);
    if (buffer[offset] & 0x80 > 0) {
      return -1 * (((buffer[offset] & 0x7f) ^ 0x7f) << 8 | ((buffer[offset + 1] & 0xff) ^ 0xff) + 1);
    }
    return buffer[offset] << 8 | (buffer[offset + 1] & 0xff);
  }
}
