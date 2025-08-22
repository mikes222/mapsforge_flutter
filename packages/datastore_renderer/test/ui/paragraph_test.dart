import 'package:datastore_renderer/src/ui/paragraph_cache.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_text_paint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  testWidgets('Tests paragraphs', (WidgetTester tester) async {
    UiTextPaint mapTextPaint = UiTextPaint()..setTextSize(10);
    UiPaint paint = UiPaint.stroke();
    {
      ParagraphEntry entry = ParagraphCache().getEntry("Südstadt", mapTextPaint, paint, 200);
      expect(entry.getWidth(), 80);
      expect(entry.getHeight(), 10);
    }
    {
      ParagraphEntry entry = ParagraphCache().getEntry("Südstadt Südstadt Südstadt", mapTextPaint, paint, 200);
      expect(entry.getWidth(), 170);
      expect(entry.getHeight(), 20);
    }
  });
}
