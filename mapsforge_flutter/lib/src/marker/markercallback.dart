import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';

abstract class MarkerCallback {
  void renderBitmap(Bitmap bitmap, double latitude, double longitude, double offsetX, double offsetY);

  void renderText(String caption, double latitude, double longitude, double offsetX, double offsetY, MapPaint stroke, double fontSize);
}
