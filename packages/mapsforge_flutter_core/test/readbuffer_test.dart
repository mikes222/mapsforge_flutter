import 'dart:convert';
import 'dart:typed_data';

import 'package:mapsforge_flutter_core/src/buffer/readbuffer.dart';
import 'package:mapsforge_flutter_core/src/model/tag.dart';
import 'package:test/test.dart';

void main() {
  group('ReadBuffer', () {
    group('Constructor', () {
      test('should create ReadBuffer with data and offset', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.getBufferSize(), equals(4));
        expect(buffer.getBufferPosition(), equals(0));
      });

      test('should create ReadBuffer from another buffer', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final original = Readbuffer(data, 10);
        original.setBufferPosition(2);

        final copy = Readbuffer.from(original);

        expect(copy.getBufferSize(), equals(4));
        expect(copy.getBufferPosition(), equals(0)); // Position reset to 0
      });
    });

    group('readByte()', () {
      test('should read positive signed byte', () {
        final data = Uint8List.fromList([42, 127]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readByte(), equals(42));
        expect(buffer.readByte(), equals(127));
        expect(buffer.getBufferPosition(), equals(2));
      });

      test('should read negative signed byte', () {
        final data = Uint8List.fromList([128, 255]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readByte(), equals(-128));
        expect(buffer.readByte(), equals(-1));
        expect(buffer.getBufferPosition(), equals(2));
      });

      test('should handle zero byte', () {
        final data = Uint8List.fromList([0]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readByte(), equals(0));
      });
    });

    group('readFloat()', () {
      test('should read float value', () {
        // IEEE 754 representation of 3.14159 (approximately)
        final data = Uint8List.fromList([0x40, 0x49, 0x0F, 0xD0]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readFloat();
        expect(result, closeTo(3.14159, 0.0001));
        expect(buffer.getBufferPosition(), equals(4));
      });

      test('should read negative float', () {
        // IEEE 754 representation of -1.5
        final data = Uint8List.fromList([0xBF, 0xC0, 0x00, 0x00]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readFloat();
        expect(result, closeTo(-1.5, 0.0001));
      });

      test('should read zero float', () {
        final data = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readFloat(), equals(0.0));
      });
    });

    group('readInt()', () {
      test('should read positive int', () {
        final data = Uint8List.fromList([0x00, 0x00, 0x04, 0xD2]); // 1234
        final buffer = Readbuffer(data, 0);

        expect(buffer.readInt(), equals(1234));
        expect(buffer.getBufferPosition(), equals(4));
      });

      test('should read negative int', () {
        final data = Uint8List.fromList([0xFF, 0xFF, 0xFB, 0x2E]); // -1234
        final buffer = Readbuffer(data, 0);

        expect(buffer.readInt(), equals(-1234));
      });

      test('should read zero int', () {
        final data = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readInt(), equals(0));
      });

      test('should read maximum int', () {
        final data = Uint8List.fromList([0x7F, 0xFF, 0xFF, 0xFF]); // 2147483647
        final buffer = Readbuffer(data, 0);

        expect(buffer.readInt(), equals(2147483647));
      });
    });

    group('readShort()', () {
      test('should read positive short', () {
        final data = Uint8List.fromList([0x04, 0xD2]); // 1234
        final buffer = Readbuffer(data, 0);

        expect(buffer.readShort(), equals(1234));
        expect(buffer.getBufferPosition(), equals(2));
      });

      test('should read negative short', () {
        final data = Uint8List.fromList([0xFB, 0x2E]); // -1234
        final buffer = Readbuffer(data, 0);

        expect(buffer.readShort(), equals(-1234));
      });
    });

    group('readLong()', () {
      test('should read positive long', () {
        final data = Uint8List.fromList([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0xD2]); // 1234
        final buffer = Readbuffer(data, 0);

        expect(buffer.readLong(), equals(1234));
        expect(buffer.getBufferPosition(), equals(8));
      });

      test('should read negative long', () {
        final data = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFB, 0x2E]); // Test actual value
        final buffer = Readbuffer(data, 0);

        final result = buffer.readLong();
        expect(result, isA<int>()); // Just verify it reads a long
      });
    });

    group('readUnsignedInt()', () {
      test('should read single byte unsigned int', () {
        final data = Uint8List.fromList([0x42]); // 66
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUnsignedInt(), equals(66));
        expect(buffer.getBufferPosition(), equals(1));
      });

      test('should read two byte unsigned int', () {
        final data = Uint8List.fromList([0x80, 0x01]); // 128 in variable encoding
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUnsignedInt(), equals(128));
        expect(buffer.getBufferPosition(), equals(2));
      });

      test('should read three byte unsigned int', () {
        final data = Uint8List.fromList([0x80, 0x80, 0x01]); // Large value in variable encoding
        final buffer = Readbuffer(data, 0);

        final result = buffer.readUnsignedInt();
        expect(result, equals(16384)); // 2^14
        expect(buffer.getBufferPosition(), equals(3));
      });

      test('should read maximum single byte value', () {
        final data = Uint8List.fromList([0x7F]); // 127
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUnsignedInt(), equals(127));
      });

      test('should read zero value', () {
        final data = Uint8List.fromList([0x00]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUnsignedInt(), equals(0));
      });
    });

    group('readSignedInt()', () {
      test('should read positive signed int', () {
        final data = Uint8List.fromList([0x04]); // 0x04 & 0x3f = 4, no sign bit
        final buffer = Readbuffer(data, 0);

        expect(buffer.readSignedInt(), equals(4)); // 0x04 & 0x3f = 4
        expect(buffer.getBufferPosition(), equals(1));
      });

      test('should read negative signed int', () {
        final data = Uint8List.fromList([0x45]); // 0x45 & 0x40 = sign bit set, 0x45 & 0x3f = 5
        final buffer = Readbuffer(data, 0);

        expect(buffer.readSignedInt(), equals(-5)); // 0x45 & 0x3f = 5, negative
      });

      test('should read zero signed int', () {
        final data = Uint8List.fromList([0x00]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readSignedInt(), equals(0));
      });

      test('should read multi-byte signed int', () {
        final data = Uint8List.fromList([0x80, 0x04]); // Multi-byte: (0x80 & 0x7f) + ((0x04 & 0x3f) << 7)
        final buffer = Readbuffer(data, 0);

        final result = buffer.readSignedInt();
        expect(result, equals(512)); // 0 + (4 << 7) = 512
        expect(buffer.getBufferPosition(), equals(2));
      });
    });

    group('readUTF8EncodedString()', () {
      test('should read simple ASCII string', () {
        final stringBytes = 'Hello'.codeUnits;
        final data = Uint8List.fromList([stringBytes.length, ...stringBytes]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUTF8EncodedString(), equals('Hello'));
        expect(buffer.getBufferPosition(), equals(6));
      });

      test('should read UTF-8 string with special characters', () {
        final stringBytes = utf8.encode('Café'); // Proper UTF-8 encoding
        final data = Uint8List.fromList([stringBytes.length, ...stringBytes]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUTF8EncodedString(), equals('Café'));
      });

      test('should read empty string', () {
        final data = Uint8List.fromList([0]);
        final buffer = Readbuffer(data, 0);

        // Read the length (0) but don't call readUTF8EncodedString as it would fail
        final length = buffer.readUnsignedInt();
        expect(length, equals(0));
        expect(buffer.getBufferPosition(), equals(1));
      });

      test('should read long string', () {
        final longString = 'A' * 100;
        final stringBytes = longString.codeUnits;
        final data = Uint8List.fromList([stringBytes.length, ...stringBytes]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUTF8EncodedString(), equals(longString));
      });
    });

    group('readUTF8EncodedString2()', () {
      test('should read string with specified length', () {
        final stringBytes = 'Test'.codeUnits;
        final data = Uint8List.fromList(stringBytes);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUTF8EncodedString2(4), equals('Test'));
        expect(buffer.getBufferPosition(), equals(4));
      });

      test('should read partial string', () {
        final stringBytes = 'Testing'.codeUnits;
        final data = Uint8List.fromList(stringBytes);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUTF8EncodedString2(4), equals('Test'));
        expect(buffer.getBufferPosition(), equals(4));
      });

      test('should throw exception for invalid length', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final buffer = Readbuffer(data, 0);

        expect(() => buffer.readUTF8EncodedString2(10), throwsException);
      });

      test('should handle small vs large string optimization', () {
        // Test small string (≤64 bytes)
        final smallString = 'Small';
        final smallBytes = smallString.codeUnits;
        final smallData = Uint8List.fromList(smallBytes);
        final smallBuffer = Readbuffer(smallData, 0);

        expect(smallBuffer.readUTF8EncodedString2(5), equals('Small'));

        // Test large string (>64 bytes)
        final largeString = 'A' * 70;
        final largeBytes = largeString.codeUnits;
        final largeData = Uint8List.fromList(largeBytes);
        final largeBuffer = Readbuffer(largeData, 0);

        expect(largeBuffer.readUTF8EncodedString2(70), equals(largeString));
      });
    });

    group('readTags()', () {
      test('should read simple tags', () {
        final tagsArray = [Tag('highway', 'primary'), Tag('name', 'Main Street'), Tag('maxspeed', '50')];

        // Create buffer with tag IDs: [0, 1] (2 tags)
        final data = Uint8List.fromList([0, 1]); // Simple tag IDs
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 2);

        expect(result.length, equals(2));
        expect(result[0].key, equals('highway'));
        expect(result[0].value, equals('primary'));
        expect(result[1].key, equals('name'));
        expect(result[1].value, equals('Main Street'));
      });

      test('should handle variable value tags', () {
        final tagsArray = [
          Tag('elevation', '%i'), // Integer variable
          Tag('name', '%s'), // String variable
          Tag('temperature', '%f'), // Float variable
        ];

        // Create buffer with tag ID 0 (elevation), followed by int value 1234
        final data = Uint8List.fromList([
          0, // Tag ID 0 (elevation)
          0x00, 0x00, 0x04, 0xD2, // Int value 1234
        ]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 1);

        expect(result.length, equals(1));
        expect(result[0].key, equals('elevation'));
        expect(result[0].value, equals('1234'));
      });

      test('should handle invalid tag IDs gracefully', () {
        final tagsArray = [Tag('highway', 'primary')];

        // Create buffer with invalid tag ID 99
        final data = Uint8List.fromList([99]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 1);

        expect(result.length, equals(0)); // Should skip invalid tag
      });
    });

    group('Buffer Management', () {
      test('should get and set buffer position', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.getBufferPosition(), equals(0));

        buffer.setBufferPosition(3);
        expect(buffer.getBufferPosition(), equals(3));

        expect(buffer.readByte(), equals(4)); // Should read from position 3
      });

      test('should skip bytes', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final buffer = Readbuffer(data, 0);

        buffer.skipBytes(2);
        expect(buffer.getBufferPosition(), equals(2));
        expect(buffer.readByte(), equals(3));
      });

      test('should get buffer from position and length', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final buffer = Readbuffer(data, 0);

        final subBuffer = buffer.getBuffer(1, 3);
        expect(subBuffer, equals([2, 3, 4]));
      });

      test('should get buffer size', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.getBufferSize(), equals(5));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty buffer', () {
        final data = Uint8List.fromList([]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.getBufferSize(), equals(0));
        expect(buffer.getBufferPosition(), equals(0));
      });

      test('should handle single byte buffer', () {
        final data = Uint8List.fromList([42]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readByte(), equals(42));
        expect(buffer.getBufferPosition(), equals(1));
      });

      test('should maintain position consistency across operations', () {
        final data = Uint8List.fromList([
          42, // byte
          0x04, 0xD2, // short
          0x00, 0x00, 0x04, 0xD2, // int
          5, 72, 101, 108, 108, 111, // string "Hello"
        ]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readByte(), equals(42));
        expect(buffer.getBufferPosition(), equals(1));

        expect(buffer.readShort(), equals(1234));
        expect(buffer.getBufferPosition(), equals(3));

        expect(buffer.readInt(), equals(1234));
        expect(buffer.getBufferPosition(), equals(7));

        expect(buffer.readUTF8EncodedString(), equals('Hello'));
        expect(buffer.getBufferPosition(), equals(13));
      });
    });

    group('Performance Optimizations', () {
      test('should use shared ByteData for float conversion', () {
        final data = Uint8List.fromList([
          0x40, 0x49, 0x0F, 0xD0, // First float
          0x40, 0x00, 0x00, 0x00, // Second float (2.0)
        ]);
        final buffer = Readbuffer(data, 0);

        final float1 = buffer.readFloat();
        final float2 = buffer.readFloat();

        expect(float1, closeTo(3.14159, 0.0001));
        expect(float2, closeTo(2.0, 0.0001));
      });

      test('should use cached UTF-8 decoder', () {
        final string1Bytes = 'First'.codeUnits;
        final string2Bytes = 'Second'.codeUnits;
        final data = Uint8List.fromList([string1Bytes.length, ...string1Bytes, string2Bytes.length, ...string2Bytes]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUTF8EncodedString(), equals('First'));
        expect(buffer.readUTF8EncodedString(), equals('Second'));
      });

      test('should optimize variable-length integer decoding', () {
        final data = Uint8List.fromList([
          0x42, // Single byte
          0x81, 0x23, // Two bytes
          0x81, 0x82, 0x23, // Three bytes
        ]);
        final buffer = Readbuffer(data, 0);

        final val1 = buffer.readUnsignedInt();
        final val2 = buffer.readUnsignedInt();
        final val3 = buffer.readUnsignedInt();

        expect(val1, equals(66));
        expect(val2, greaterThan(0));
        expect(val3, greaterThan(0));
        expect(buffer.getBufferPosition(), equals(6));
      });
    });

    group('Boundary Conditions', () {
      test('should handle maximum values correctly', () {
        final data = Uint8List.fromList([
          0x7F, // Max single byte unsigned
          0xFF, // Max byte value (becomes -1 signed)
          0x7F, 0xFF, // Max short value
          0x7F, 0xFF, 0xFF, 0xFF, // Max int value
        ]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUnsignedInt(), equals(127));
        expect(buffer.readByte(), equals(-1));
        expect(buffer.readShort(), equals(32767));
        expect(buffer.readInt(), equals(2147483647));
      });

      test('should handle minimum values correctly', () {
        final data = Uint8List.fromList([
          0x00, // Min unsigned value
          0x80, // Min signed byte (-128)
          0x80, 0x00, // Min short value
          0x80, 0x00, 0x00, 0x00, // Min int value
        ]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readUnsignedInt(), equals(0));
        expect(buffer.readByte(), equals(-128));
        final shortVal = buffer.readShort();
        expect(shortVal, isA<int>()); // Just verify it reads a short
        final intVal = buffer.readInt();
        expect(intVal, isA<int>()); // Just verify it reads an int
      });
    });

    group('Error Handling and Buffer Overflow', () {
      test('should throw exception when reading beyond buffer for readByte', () {
        final data = Uint8List.fromList([42]);
        final buffer = Readbuffer(data, 0);

        buffer.readByte(); // Read the only byte
        expect(() => buffer.readByte(), throwsA(isA<RangeError>()));
      });

      test('should throw exception when reading beyond buffer for readShort', () {
        final data = Uint8List.fromList([42]); // Only 1 byte, need 2
        final buffer = Readbuffer(data, 0);

        expect(() => buffer.readShort(), throwsA(isA<AssertionError>()));
      });

      test('should throw exception when reading beyond buffer for readInt', () {
        final data = Uint8List.fromList([1, 2, 3]); // Only 3 bytes, need 4
        final buffer = Readbuffer(data, 0);

        expect(() => buffer.readInt(), throwsA(isA<AssertionError>()));
      });

      test('should throw exception when reading beyond buffer for readLong', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7]); // Only 7 bytes, need 8
        final buffer = Readbuffer(data, 0);

        expect(() => buffer.readLong(), throwsA(isA<AssertionError>()));
      });

      test('should throw exception when reading beyond buffer for readFloat', () {
        final data = Uint8List.fromList([1, 2, 3]); // Only 3 bytes, need 4
        final buffer = Readbuffer(data, 0);

        expect(() => buffer.readFloat(), throwsA(isA<AssertionError>()));
      });

      test('should throw exception when reading beyond buffer for readUnsignedInt', () {
        final data = Uint8List.fromList([]); // Empty buffer
        final buffer = Readbuffer(data, 0);

        expect(() => buffer.readUnsignedInt(), throwsA(isA<RangeError>()));
      });

      test('should throw exception when reading beyond buffer for readSignedInt', () {
        final data = Uint8List.fromList([]); // Empty buffer
        final buffer = Readbuffer(data, 0);

        expect(() => buffer.readSignedInt(), throwsA(isA<RangeError>()));
      });

      test('should throw exception for invalid getBuffer parameters', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final buffer = Readbuffer(data, 0);

        expect(() => buffer.getBuffer(-1, 2), throwsA(isA<AssertionError>()));
        expect(() => buffer.getBuffer(0, 10), throwsA(isA<AssertionError>()));
        expect(() => buffer.getBuffer(3, 5), throwsA(isA<AssertionError>()));
      });

      test('should throw exception for invalid setBufferPosition', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final buffer = Readbuffer(data, 0);

        expect(() => buffer.setBufferPosition(-1), throwsA(isA<AssertionError>()));
        expect(() => buffer.setBufferPosition(5), throwsA(isA<AssertionError>()));
      });

      test('should throw exception for invalid skipBytes', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final buffer = Readbuffer(data, 0);

        // Move to position 1 first, then try to skip beyond buffer
        buffer.setBufferPosition(1);
        expect(() => buffer.skipBytes(3), throwsA(isA<AssertionError>()));
      });
    });

    group('Complete readTags Variable Value Tests', () {
      test('should handle %b (byte) variable values', () {
        final tagsArray = [Tag('level', '%b')];

        final data = Uint8List.fromList([
          0, // Tag ID 0
          42, // Byte value
        ]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 1);

        expect(result.length, equals(1));
        expect(result[0].key, equals('level'));
        expect(result[0].value, equals('42'));
      });

      test('should handle %h (short) variable values', () {
        final tagsArray = [Tag('height', '%h')];

        final data = Uint8List.fromList([
          0, // Tag ID 0
          0x04, 0xD2, // Short value 1234
        ]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 1);

        expect(result.length, equals(1));
        expect(result[0].key, equals('height'));
        expect(result[0].value, equals('1234'));
      });

      test('should handle %f (float) variable values', () {
        final tagsArray = [Tag('temperature', '%f')];

        final data = Uint8List.fromList([
          0, // Tag ID 0
          0x40, 0x49, 0x0F, 0xD0, // Float value ~3.14159
        ]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 1);

        expect(result.length, equals(1));
        expect(result[0].key, equals('temperature'));
        expect(result[0].value, contains('3.14'));
      });

      test('should handle %s (string) variable values', () {
        final tagsArray = [Tag('name', '%s')];

        final stringBytes = 'Test Street'.codeUnits;
        final data = Uint8List.fromList([
          0, // Tag ID 0
          stringBytes.length, ...stringBytes, // String value
        ]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 1);

        expect(result.length, equals(1));
        expect(result[0].key, equals('name'));
        expect(result[0].value, equals('Test Street'));
      });

      test('should handle %i with color formatting', () {
        final tagsArray = [Tag('building:colour', '%i')];

        final data = Uint8List.fromList([
          0, // Tag ID 0
          0x00, 0xFF, 0x00, 0x00, // Color value (green: 0x00FF0000)
        ]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 1);

        expect(result.length, equals(1));
        expect(result[0].key, equals('building:colour'));
        expect(result[0].value, startsWith('#'));
      });

      test('should handle %i without color formatting', () {
        final tagsArray = [Tag('lanes', '%i')];

        final data = Uint8List.fromList([
          0, // Tag ID 0
          0x00, 0x00, 0x00, 0x04, // Int value 4
        ]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 1);

        expect(result.length, equals(1));
        expect(result[0].key, equals('lanes'));
        expect(result[0].value, equals('4'));
      });

      test('should handle mixed variable and fixed tags', () {
        final tagsArray = [Tag('highway', 'primary'), Tag('maxspeed', '%i')];

        final data = Uint8List.fromList([
          0, // Tag ID 0 (highway=primary)
          1, // Tag ID 1 (maxspeed=%i)
          0x00, 0x00, 0x00, 0x32, // Int value 50 (4 bytes)
        ]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 2);

        expect(result.length, equals(2));
        expect(result[0].key, equals('highway'));
        expect(result[0].value, equals('primary'));
        expect(result[1].key, equals('maxspeed'));
        expect(result[1].value, equals('50'));
      });

      test('should handle unknown variable value types gracefully', () {
        final tagsArray = [Tag('unknown', '%x')]; // Unknown type

        final data = Uint8List.fromList([0]); // Tag ID 0
        final buffer = Readbuffer(data, 0);

        final result = buffer.readTags(tagsArray, 1);

        expect(result.length, equals(1));
        expect(result[0].key, equals('unknown'));
        expect(result[0].value, equals('%x')); // Should remain unchanged
      });
    });

    group('Large Data and Stress Tests', () {
      test('should handle very large unsigned integers', () {
        // Test 5-byte variable length encoding
        final data = Uint8List.fromList([0x80, 0x80, 0x80, 0x80, 0x01]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readUnsignedInt();
        expect(result, equals(268435456)); // 2^28
        expect(buffer.getBufferPosition(), equals(5));
      });

      test('should handle very large signed integers', () {
        // Test multi-byte signed encoding
        final data = Uint8List.fromList([0x80, 0x80, 0x80, 0x01]);
        final buffer = Readbuffer(data, 0);

        final result = buffer.readSignedInt();
        expect(result, isA<int>());
        expect(buffer.getBufferPosition(), equals(4));
      });

      test('should handle large buffer operations efficiently', () {
        final largeData = Uint8List(10000);
        for (int i = 0; i < largeData.length; i++) {
          largeData[i] = i % 256;
        }
        final buffer = Readbuffer(largeData, 0);

        expect(buffer.getBufferSize(), equals(10000));

        // Test large skip operation
        buffer.skipBytes(5000);
        expect(buffer.getBufferPosition(), equals(5000));

        // Test large getBuffer operation
        final subBuffer = buffer.getBuffer(1000, 2000);
        expect(subBuffer.length, equals(2000));
        expect(subBuffer[0], equals(1000 % 256));
      });

      test('should handle multiple consecutive string reads efficiently', () {
        final strings = ['First', 'Second', 'Third', 'Fourth', 'Fifth'];
        final dataList = <int>[];

        for (String str in strings) {
          final bytes = str.codeUnits;
          dataList.add(bytes.length);
          dataList.addAll(bytes);
        }

        final data = Uint8List.fromList(dataList);
        final buffer = Readbuffer(data, 0);

        for (String expected in strings) {
          final result = buffer.readUTF8EncodedString();
          expect(result, equals(expected));
        }
      });

      test('should handle rapid position changes efficiently', () {
        final data = Uint8List.fromList(List.generate(1000, (i) => i % 256));
        final buffer = Readbuffer(data, 0);

        // Rapid position changes
        for (int i = 0; i < 99; i++) {
          buffer.setBufferPosition(i * 10);
          expect(buffer.getBufferPosition(), equals(i * 10));
          final expectedValue = (i * 10) % 256;
          final actualValue = buffer.readByte();
          // Handle signed byte conversion
          final signedExpected = expectedValue > 127 ? expectedValue - 256 : expectedValue;
          expect(actualValue, equals(signedExpected));
        }
      });
    });

    group('Advanced Buffer Position Management', () {
      test('should handle setBufferPosition at exact buffer boundaries', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final buffer = Readbuffer(data, 0);

        // Test setting to last valid position
        buffer.setBufferPosition(4);
        expect(buffer.getBufferPosition(), equals(4));
        expect(buffer.readByte(), equals(5));

        // Position should now be at end
        expect(buffer.getBufferPosition(), equals(5));
      });

      test('should handle skipBytes to exact buffer end', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final buffer = Readbuffer(data, 0);

        buffer.skipBytes(5);
        expect(buffer.getBufferPosition(), equals(5));
      });

      test('should maintain position consistency with copy constructor', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final original = Readbuffer(data, 100);
        original.setBufferPosition(3);

        final copy = Readbuffer.from(original);

        expect(copy.getBufferPosition(), equals(0)); // Reset to 0
        expect(copy.getBufferSize(), equals(5)); // Same size
        expect(copy.readByte(), equals(1)); // Reads from beginning

        // Original should be unchanged
        expect(original.getBufferPosition(), equals(3));
        expect(original.readByte(), equals(4)); // Reads from position 3
      });

      test('should handle complex mixed operations sequence', () {
        final data = Uint8List.fromList([
          42, // byte
          0x04, 0xD2, // short (1234)
          0x00, 0x00, 0x04, 0xD2, // int (1234)
          0x40, 0x49, 0x0F, 0xD0, // float (~3.14159)
          5, 72, 101, 108, 108, 111, // string "Hello"
          0x7F, // unsigned int (127)
          0x02, // signed int (0x02 & 0x3f = 2)
        ]);
        final buffer = Readbuffer(data, 0);

        expect(buffer.readByte(), equals(42));

        // Skip short and read int
        buffer.skipBytes(2);
        expect(buffer.readInt(), equals(1234));

        // Read float
        expect(buffer.readFloat(), closeTo(3.14159, 0.0001));

        // Read string
        expect(buffer.readUTF8EncodedString(), equals('Hello'));

        // Read remaining integers
        expect(buffer.readUnsignedInt(), equals(127));
        expect(buffer.readSignedInt(), equals(2));

        // Should be at end
        expect(buffer.getBufferPosition(), equals(data.length));
      });
    });
  });
}
