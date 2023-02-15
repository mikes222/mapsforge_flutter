import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/flutterpaint.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/paragraph_cache.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  testWidgets('Tests paragraphs', (WidgetTester tester) async {
    MapTextPaint mapTextPaint = FlutterTextPaint()..setTextSize(10);
    MapPaint paint = FlutterPaint(Paint())..setColor(Colors.black);
    {
      ParagraphEntry entry =
          ParagraphCache().getEntry("Südstadt", mapTextPaint, paint, 200);
      expect(entry.getWidth(), 80);
      expect(entry.getHeight(), 10);
    }
    {
      ParagraphEntry entry = ParagraphCache()
          .getEntry("Südstadt Südstadt Südstadt", mapTextPaint, paint, 200);
      expect(entry.getWidth(), 170);
      expect(entry.getHeight(), 20);
    }
  });
}
