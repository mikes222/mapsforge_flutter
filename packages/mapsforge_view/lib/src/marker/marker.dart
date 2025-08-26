import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:mapsforge_view/mapsforge.dart';

abstract class Marker<T> {
  final ZoomlevelRange zoomlevelRange;

  /// the item this marker represents.
  ///
  /// This property is NOT used by mapsforge. It can be used by the developer to reference to the source of this marker, e.g. a database entry.
  T? item;

  Marker({this.zoomlevelRange = const ZoomlevelRange.standard(), this.item});

  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection);

  ///
  /// Renders this object. Called by markerPainter
  ///
  void render(UiRenderContext renderContext);

  /// returns true if this marker is within the visible boundary and therefore should be painted. Since the initResources() is called
  /// only if shouldPoint() returns true, do not test for available resources here.
  bool shouldPaint(BoundingBox boundary, int zoomlevel) {
    return zoomlevelRange.isWithin(zoomlevel);
  }

  /// returns true if the position specified by [tapEvent] is in the area of
  /// this marker. Note that tapEvent represents the position at the time the
  /// tap has been executed.
  bool isTapped(TapEvent tapEvent) {
    return false;
  }

  void dispose() {}
}
