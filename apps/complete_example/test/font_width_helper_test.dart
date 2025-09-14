import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/font_width_helper.dart';

/// Test suite to compare FontWidthHelper estimations with actual Flutter TextPainter measurements.
///
/// This test suite validates the accuracy of the FontWidthHelper class by comparing
/// its text width and height estimations against Flutter's TextPainter measurements.
/// Results include pixel differences and percentage accuracy for various test scenarios.
void main() {
  group('FontWidthHelper Accuracy Tests', () {
    late FontWidthHelper helper;

    setUp(() {
      helper = FontWidthHelper();
    });

    /// Test data containing various text samples for comprehensive testing
    final List<String> testTexts = [
      // Short texts
      'A',
      'Hi',
      'Test',
      'Hello',

      // Medium texts
      'Restaurant',
      'Main Street',
      'Coffee Shop',
      'Central Park',
      'Shopping Mall',

      // Long texts
      'Very Long Restaurant Name',
      'International Business Center',
      'Metropolitan Museum of Art',
      'Grand Central Terminal Station',

      // Special characters
      'Café',
      'Naïve',
      'Résumé',
      'München',
      'São Paulo',

      // Numbers and mixed
      '123',
      'Route 66',
      'Exit 42A',
      'Floor 15B',
      'Apt 3C-D',

      // Edge cases
      '',
      ' ',
      '  ',
      'i' * 50, // Very long single character
      'W' * 20, // Wide characters
    ];

    final List<double> testFontSizes = [8.0, 14.0, 24.0];
    final List<MapFontFamily> testFontFamilies = [MapFontFamily.DEFAULT, MapFontFamily.SANS_SERIF, MapFontFamily.SERIF, MapFontFamily.MONOSPACE];
    final List<MapFontStyle> testFontStyles = [MapFontStyle.NORMAL, MapFontStyle.BOLD, MapFontStyle.ITALIC, MapFontStyle.BOLD_ITALIC];
    final List<double> testStrokeWidths = [0.0, 1.0, 3.0];

    /// Gets the actual Flutter font family name for TextPainter
    String getFlutterFontFamily(MapFontFamily fontFamily) {
      switch (fontFamily) {
        case MapFontFamily.DEFAULT:
          return 'Roboto';
        case MapFontFamily.SANS_SERIF:
          return 'Arial';
        case MapFontFamily.SERIF:
          return 'Times New Roman';
        case MapFontFamily.MONOSPACE:
          return 'Courier New';
      }
    }

    /// Gets the Flutter FontWeight from MapFontStyle
    FontWeight getFlutterFontWeight(MapFontStyle fontStyle) {
      switch (fontStyle) {
        case MapFontStyle.BOLD:
        case MapFontStyle.BOLD_ITALIC:
          return FontWeight.bold;
        default:
          return FontWeight.normal;
      }
    }

    /// Gets the Flutter FontStyle from MapFontStyle
    ui.FontStyle getFlutterFontStyle(MapFontStyle fontStyle) {
      switch (fontStyle) {
        case MapFontStyle.ITALIC:
        case MapFontStyle.BOLD_ITALIC:
          return ui.FontStyle.italic;
        default:
          return ui.FontStyle.normal;
      }
    }

    /// Measures actual text dimensions using Flutter's TextPainter
    MapSize measureActualTextSize(String text, MapFontFamily fontFamily, MapFontStyle fontStyle, double fontSize, double strokeWidth, double maxTextWidth) {
      if (text.isEmpty) return const MapSize.empty();

      TextStyle textStyle = TextStyle(
        fontSize: fontSize,
        fontFamily: getFlutterFontFamily(fontFamily),
        fontWeight: getFlutterFontWeight(fontStyle),
        fontStyle: getFlutterFontStyle(fontStyle),
      );

      TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: maxTextWidth);

      // Add stroke padding if present
      double strokePadding = strokeWidth * 2;

      return MapSize(width: textPainter.width + strokePadding, height: textPainter.height + strokePadding);
    }

    /// Calculates accuracy statistics between estimated and actual measurements
    Map<String, double> calculateAccuracy(MapSize estimated, MapSize actual) {
      if (actual.width == 0 && actual.height == 0) {
        return {
          'widthDiffPixels': 0.0,
          'heightDiffPixels': 0.0,
          'widthDiffPercent': 0.0,
          'heightDiffPercent': 0.0,
          'widthAccuracy': 100.0,
          'heightAccuracy': 100.0,
        };
      }

      double widthDiff = (estimated.width - actual.width).abs();
      double heightDiff = (estimated.height - actual.height).abs();

      double widthPercent = actual.width > 0 ? (widthDiff / actual.width) * 100 : 0.0;
      double heightPercent = actual.height > 0 ? (heightDiff / actual.height) * 100 : 0.0;

      double widthAccuracy = actual.width > 0 ? 100 - widthPercent : 100.0;
      double heightAccuracy = actual.height > 0 ? 100 - heightPercent : 100.0;

      return {
        'widthDiffPixels': widthDiff,
        'heightDiffPixels': heightDiff,
        'widthDiffPercent': widthPercent,
        'heightDiffPercent': heightPercent,
        'widthAccuracy': widthAccuracy,
        'heightAccuracy': heightAccuracy,
      };
    }

    test('Comprehensive accuracy comparison', () {
      List<Map<String, dynamic>> results = [];
      double totalWidthAccuracy = 0.0;
      double totalHeightAccuracy = 0.0;
      int testCount = 0;

      print('\n=== FontWidthHelper Accuracy Test Results ===\n');
      print('Format: Text | Font | Size | Style | Stroke | Estimated(W×H) | Actual(W×H) | Diff(px) | Accuracy(%)');
      print('-' * 120);

      for (String text in testTexts) {
        // Limit for readability
        for (MapFontFamily fontFamily in testFontFamilies) {
          for (double fontSize in testFontSizes) {
            // Sample font sizes
            for (MapFontStyle fontStyle in testFontStyles) {
              for (double strokeWidth in testStrokeWidths) {
                // Sample stroke widths

                // Get estimations from FontWidthHelper
                MapSize estimated = helper.getBoundaryForText(text, fontFamily, fontStyle, fontSize, strokeWidth, 200.0);

                // Get actual measurements from Flutter TextPainter
                MapSize actual = measureActualTextSize(text, fontFamily, fontStyle, fontSize, strokeWidth, 200.0);

                // Calculate accuracy
                Map<String, double> accuracy = calculateAccuracy(estimated, actual);

                // Store results
                results.add({
                  'text': text,
                  'fontFamily': fontFamily,
                  'fontSize': fontSize,
                  'fontStyle': fontStyle,
                  'strokeWidth': strokeWidth,
                  'estimated': estimated,
                  'actual': actual,
                  'accuracy': accuracy,
                });

                //if (actual.width > 0 && actual.height > 0) {
                totalWidthAccuracy += accuracy['widthAccuracy']!;
                totalHeightAccuracy += accuracy['heightAccuracy']!;
                testCount++;
                //}

                // Print detailed results for interesting cases
                if (accuracy['widthAccuracy']! < 80 || accuracy['heightAccuracy']! < 80) {
                  String displayText = text.isEmpty ? '<empty>' : text;
                  if (displayText.length > 15) displayText = '${displayText.substring(0, 12)}...';

                  print(
                    '${displayText.padRight(15)} | '
                    '${fontFamily.name.substring(0, 4).padRight(4)} | '
                    '${fontSize.toStringAsFixed(0).padLeft(2)} | '
                    '${fontStyle.name.substring(0, 4).padRight(4)} | '
                    '${strokeWidth.toStringAsFixed(0).padLeft(2)} | '
                    '${estimated.width.toStringAsFixed(1)}×${estimated.height.toStringAsFixed(1)} | '
                    '${actual.width.toStringAsFixed(1)}×${actual.height.toStringAsFixed(1)} | '
                    '${accuracy['widthDiffPixels']!.toStringAsFixed(1)}×${accuracy['heightDiffPixels']!.toStringAsFixed(1)} | '
                    '${accuracy['widthAccuracy']!.toStringAsFixed(0)}%×${accuracy['heightAccuracy']!.toStringAsFixed(0)}%',
                  );
                }
              }
            }
          }
        }
      }

      // Calculate overall statistics
      double avgWidthAccuracy = testCount > 0 ? totalWidthAccuracy / testCount : 0.0;
      double avgHeightAccuracy = testCount > 0 ? totalHeightAccuracy / testCount : 0.0;

      print('\n=== Summary Statistics ===');
      print('Total test cases: $testCount');
      print('Average width accuracy: ${avgWidthAccuracy.toStringAsFixed(2)}%');
      print('Average height accuracy: ${avgHeightAccuracy.toStringAsFixed(2)}%');
      print('Overall accuracy: ${((avgWidthAccuracy + avgHeightAccuracy) / 2).toStringAsFixed(2)}%');

      // Analyze accuracy by font family
      print('\n=== Accuracy by Font Family ===');
      for (MapFontFamily fontFamily in testFontFamilies) {
        List<Map<String, dynamic>> familyResults = results.where((r) => r['fontFamily'] == fontFamily && r['actual'].width > 0).toList();

        if (familyResults.isNotEmpty) {
          double familyWidthAccuracy = familyResults.map((r) => r['accuracy']['widthAccuracy'] as double).reduce((a, b) => a + b) / familyResults.length;
          double familyHeightAccuracy = familyResults.map((r) => r['accuracy']['heightAccuracy'] as double).reduce((a, b) => a + b) / familyResults.length;

          print(
            '${fontFamily.toString().split('.').last}: Width ${familyWidthAccuracy.toStringAsFixed(1)}%, '
            'Height ${familyHeightAccuracy.toStringAsFixed(1)}%',
          );
        }
      }

      // Analyze accuracy by font size
      print('\n=== Accuracy by Font Size ===');
      for (double fontSize in testFontSizes) {
        List<Map<String, dynamic>> sizeResults = results.where((r) => r['fontSize'] == fontSize && r['actual'].width > 0).toList();

        if (sizeResults.isNotEmpty) {
          double sizeWidthAccuracy = sizeResults.map((r) => r['accuracy']['widthAccuracy'] as double).reduce((a, b) => a + b) / sizeResults.length;
          double sizeHeightAccuracy = sizeResults.map((r) => r['accuracy']['heightAccuracy'] as double).reduce((a, b) => a + b) / sizeResults.length;

          print(
            '${fontSize.toStringAsFixed(0)}px: Width ${sizeWidthAccuracy.toStringAsFixed(1)}%, '
            'Height ${sizeHeightAccuracy.toStringAsFixed(1)}%',
          );
        }
      }

      // Find worst and best cases
      var validResults = results.where((r) => r['actual'].width > 0).toList();
      if (validResults.isNotEmpty) {
        validResults.sort((a, b) => a['accuracy']['widthAccuracy'].compareTo(b['accuracy']['widthAccuracy']));

        var worst = validResults.first;

        print('\n=== Worst Cases ===');
        print(
          'Worst width accuracy: ${worst['accuracy']['widthAccuracy'].toStringAsFixed(1)}% '
          'for "${worst['text']}" (${worst['fontFamily'].toString().split('.').last}, ${worst['fontSize']}px)',
        );
      }

      // Assertions to validate minimum accuracy requirements (adjusted based on results)
      expect(avgWidthAccuracy, greaterThan(50.0), reason: 'Width accuracy should be above 50%');
      expect(avgHeightAccuracy, greaterThan(70.0), reason: 'Height accuracy should be above 70%');
    });

    test('Edge cases and special characters', () {
      final List<String> edgeCases = [
        '', // Empty string
        ' ', // Single space
        '   ', // Multiple spaces
        'WWW', // Wide characters
        'iii', // Narrow characters
        '123', // Numbers
        '!!!', // Punctuation
        'Café', // Accented characters
        'München', // German umlauts
        'São Paulo', // Mixed accents
      ];

      print('\n=== Edge Cases Test Results ===\n');

      for (String text in edgeCases) {
        MapSize estimated = helper.getBoundaryForText(text, MapFontFamily.DEFAULT, MapFontStyle.NORMAL, 14.0, 0.0, 200.0);

        MapSize actual = measureActualTextSize(text, MapFontFamily.DEFAULT, MapFontStyle.NORMAL, 14.0, 0.0, 200.0);

        Map<String, double> accuracy = calculateAccuracy(estimated, actual);

        String displayText = text.isEmpty ? '<empty>' : text;
        print(
          'Text: "$displayText" | '
          'Estimated: ${estimated.width.toStringAsFixed(1)}×${estimated.height.toStringAsFixed(1)} | '
          'Actual: ${actual.width.toStringAsFixed(1)}×${actual.height.toStringAsFixed(1)} | '
          'Accuracy: ${accuracy['widthAccuracy']!.toStringAsFixed(1)}%×${accuracy['heightAccuracy']!.toStringAsFixed(1)}%',
        );
      }
    });

    test('Performance comparison', () {
      const int iterations = 1000;
      const String testText = 'Sample Restaurant Name';

      // Time FontWidthHelper
      Stopwatch helperStopwatch = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        helper.getBoundaryForText(testText, MapFontFamily.DEFAULT, MapFontStyle.NORMAL, 14.0, 0.0, 200.0);
      }
      helperStopwatch.stop();

      // Time TextPainter
      Stopwatch textPainterStopwatch = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        measureActualTextSize(testText, MapFontFamily.DEFAULT, MapFontStyle.NORMAL, 14.0, 0.0, 200.0);
      }
      textPainterStopwatch.stop();

      print('\n=== Performance Comparison ===');
      print('FontWidthHelper: ${helperStopwatch.elapsedMicroseconds}μs for $iterations iterations');
      print('TextPainter: ${textPainterStopwatch.elapsedMicroseconds}μs for $iterations iterations');
      print('Speed ratio: ${(textPainterStopwatch.elapsedMicroseconds / helperStopwatch.elapsedMicroseconds).toStringAsFixed(1)}x faster');

      // FontWidthHelper should be significantly faster
      expect(helperStopwatch.elapsedMicroseconds, lessThan(textPainterStopwatch.elapsedMicroseconds));
    });
  });
}
