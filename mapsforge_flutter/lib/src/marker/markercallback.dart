import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

abstract class MarkerCallback {
  void renderBitmap(Bitmap bitmap, double latitude, double longitude,
      double offsetX, double offsetY, double rotation, MapPaint paint);

  void renderPath(MapPath path, MapPaint paint);

  void renderPathText(String caption, LineString lineString, Mappoint origin,
      MapPaint stroke, MapTextPaint textPaint, double maxTextWidth);

  void renderRect(MapRect rect, MapPaint paint);

  void renderCircle(
      double latitude, double longitude, double radius, MapPaint paint);

  MapViewPosition get mapViewPosition;

  FlutterCanvas get flutterCanvas;
}
