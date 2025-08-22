import 'dart:ui' as ui;

import 'package:datastore_renderer/src/ui/ui_canvas.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Enable Flutter's binding for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  // Directory where golden files will be stored
  const goldenDir = 'goldens';

  const double tileSize = 256;

  // Test case for the drawCircle method
  testWidgets('UiCanvas.drawCircle renders correctly', (WidgetTester tester) async {
    // Define test parameters
    const circleX = 100.0;
    const circleY = 100.0;
    const radius = 50.0;

    // Create a paint object for the circle
    final paint = UiPaint.fill()..setColor(const Color.fromARGB(255, 255, 0, 0)); // Red color

    // Create a key to identify our CustomPaint widget
    final testKey = UniqueKey();

    // Create a container to render the canvas
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            key: testKey,
            size: const Size(tileSize, tileSize),
            painter: _TestPainter(
              onPaint: (canvas, size) {
                // Create a UiCanvas with the provided canvas
                final uiCanvas = UiCanvas(canvas, size);

                // Draw a circle using the UiCanvas
                uiCanvas.drawCircle(circleX, circleY, radius, paint);
              },
            ),
          ),
        ),
      ),
    );

    // Verify the golden file matches the rendered output
    await expectLater(find.byKey(testKey), matchesGoldenFile('$goldenDir/ui_canvas_draw_circle_fill.png'));
  });

  // Test case for the drawCircle method with stroke style
  testWidgets('UiCanvas.drawCircle with stroke style renders correctly', (WidgetTester tester) async {
    // Define test parameters
    const circleX = 100.0;
    const circleY = 100.0;
    const radius = 50.0;

    // Create a paint object for the circle with stroke style
    final paint = UiPaint.stroke()
      ..setColor(const Color.fromARGB(255, 0, 0, 255)) // Blue color
      ..setStrokeWidth(5.0);

    // Create a key to identify our CustomPaint widget
    final testKey = UniqueKey();

    // Create a container to render the canvas
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            key: testKey,
            size: const Size(tileSize, tileSize),
            painter: _TestPainter(
              onPaint: (canvas, size) {
                // Create a UiCanvas with the provided canvas
                final uiCanvas = UiCanvas(canvas, size);

                // Draw a circle using the UiCanvas with stroke style
                uiCanvas.drawCircle(circleX, circleY, radius, paint);
              },
            ),
          ),
        ),
      ),
    );

    // Verify the golden file matches the rendered output
    await expectLater(find.byKey(testKey), matchesGoldenFile('$goldenDir/ui_canvas_draw_circle_stroke.png'));
  });

  testWidgets('UiCanvas.fillColorFromNumber renders correctly', (WidgetTester tester) async {
    // Create a key to identify our CustomPaint widget
    final testKey = UniqueKey();

    // Create a container to render the canvas
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            key: testKey,
            size: const Size(tileSize, tileSize),
            painter: _TestPainter(
              onPaint: (canvas, size) {
                // Create a UiCanvas with the provided canvas
                final uiCanvas = UiCanvas(canvas, size);

                // Draw a circle using the UiCanvas with stroke style
                uiCanvas.fillColorFromNumber(0xffebc378);
              },
            ),
          ),
        ),
      ),
    );

    // Verify the golden file matches the rendered output
    await expectLater(find.byKey(testKey), matchesGoldenFile('$goldenDir/ui_canvas_fill_color_from_number.png'));
  });

  testWidgets('UiCanvas.drawLine renders correctly', (WidgetTester tester) async {
    // Define test parameters
    const startX = 100.0;
    const startY = 100.0;
    const endX = 200.0;
    const endY = 150.0;

    // Create a paint object for the circle with stroke style
    final paint = UiPaint.stroke()
      ..setColor(const Color.fromARGB(255, 40, 90, 200)) // Blue color
      ..setStrokeWidth(5.0);

    // Create a key to identify our CustomPaint widget
    final testKey = UniqueKey();

    // Create a container to render the canvas
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            key: testKey,
            size: const Size(tileSize, tileSize),
            painter: _TestPainter(
              onPaint: (canvas, size) {
                // Create a UiCanvas with the provided canvas
                final uiCanvas = UiCanvas(canvas, size);

                // Draw a circle using the UiCanvas with stroke style
                uiCanvas.drawLine(startX, startY, endX, endY, paint);
              },
            ),
          ),
        ),
      ),
    );

    // Verify the golden file matches the rendered output
    await expectLater(find.byKey(testKey), matchesGoldenFile('$goldenDir/ui_canvas_draw_line.png'));
  });
}

// A custom painter that delegates to a callback
class _TestPainter extends CustomPainter {
  final void Function(ui.Canvas canvas, ui.Size size) onPaint;

  const _TestPainter({required this.onPaint});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    onPaint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _TestPainter oldDelegate) => false;
}
