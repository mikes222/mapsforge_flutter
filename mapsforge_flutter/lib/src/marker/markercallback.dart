import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/model/latlong.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

abstract class MarkerCallback {
  void renderBitmap(Bitmap bitmap, double latitude, double longitude, double offsetX, double offsetY, double rotation, MapPaint paint);

  void renderText(String caption, double latitude, double longitude, double offsetX, double offsetY, MapPaint stroke, double fontSize);

  void renderPath(MapPath path, MapPaint paint);

  void renderCircle(double latitude, double longitude, double radius, MapPaint paint);

  GraphicFactory get graphicFactory;

  MapViewPosition get mapViewPosition;
}
