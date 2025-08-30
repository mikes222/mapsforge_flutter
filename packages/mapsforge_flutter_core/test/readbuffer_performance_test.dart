import 'dart:typed_data';

import 'package:mapsforge_flutter_core/src/buffer/readbuffer.dart';
import 'package:test/test.dart';

void main() {
  group('ReadBuffer Performance Tests', () {
    late Uint8List testData;

    setUp(() {
      // Create test data with various patterns
      testData = Uint8List(10000);
      for (int i = 0; i < testData.length; i++) {
        testData[i] = i % 256;
      }
    });

    test('readByte performance', () {
      final buffer = Readbuffer(testData, 0);
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        buffer.setBufferPosition(i % (testData.length - 1));
        buffer.readByte();
      }

      stopwatch.stop();
      print('readByte: ${stopwatch.elapsedMicroseconds} microseconds for 1000 operations');
      expect(stopwatch.elapsedMicroseconds, lessThan(10000)); // Should be under 10ms
    });

    test('readUnsignedInt performance', () {
      // Create test data with variable-length integers
      final varIntData = Uint8List(1000);
      int pos = 0;

      // Fill with various variable-length integers
      for (int i = 0; i < 100; i++) {
        int value = i * 127; // Create values that require multiple bytes
        while (value >= 0x80 && pos < varIntData.length - 1) {
          varIntData[pos++] = (value & 0x7F) | 0x80;
          value >>= 7;
        }
        if (pos < varIntData.length) {
          varIntData[pos++] = value & 0x7F;
        }
      }

      final buffer = Readbuffer(varIntData, 0);
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        buffer.setBufferPosition(0);
        while (buffer.getBufferPosition() < pos - 1) {
          try {
            buffer.readUnsignedInt();
          } catch (e) {
            break;
          }
        }
      }

      stopwatch.stop();
      print('readUnsignedInt: ${stopwatch.elapsedMicroseconds} microseconds for 100 iterations');
      expect(stopwatch.elapsedMicroseconds, lessThan(50000)); // Should be under 50ms
    });

    test('readUTF8EncodedString performance', () {
      // Create test data with UTF-8 strings
      final stringData = 'Hello, World! This is a test string with special characters.';
      final utf8Bytes = stringData.codeUnits;
      final testBuffer = Uint8List.fromList([
        utf8Bytes.length, // Length prefix
        ...utf8Bytes,
      ]);

      final buffer = Readbuffer(testBuffer, 0);
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        buffer.setBufferPosition(0);
        final length = buffer.readByte();
        buffer.readUTF8EncodedString2(length);
      }

      stopwatch.stop();
      print('readUTF8EncodedString: ${stopwatch.elapsedMicroseconds} microseconds for 1000 operations');
      expect(stopwatch.elapsedMicroseconds, lessThan(20000)); // Should be under 20ms
    });

    test('readFloat performance', () {
      // Create test data with float values
      final floatData = Uint8List(4000); // 1000 floats * 4 bytes each
      for (int i = 0; i < floatData.length; i += 4) {
        // Create some float bit patterns
        floatData[i] = 0x42;
        floatData[i + 1] = 0x28;
        floatData[i + 2] = 0x00;
        floatData[i + 3] = 0x00;
      }

      final buffer = Readbuffer(floatData, 0);
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        buffer.setBufferPosition(0);
        buffer.readFloat();
      }

      stopwatch.stop();
      print('readFloat: ${stopwatch.elapsedMicroseconds} microseconds for 1000 operations');
      expect(stopwatch.elapsedMicroseconds, lessThan(15000)); // Should be under 15ms
    });
  });
}
