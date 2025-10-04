import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/marker/abstract_poi_marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';

/// A [ClusterMarker] is a special marker that represents a group of markers that
/// have been clustered together to reduce clutter on the map.
///
/// The marker typically displays a count of the number of individual markers it
/// represents. When the user zooms in, the cluster may break apart, revealing
/// the individual markers or smaller clusters.
class ClusterMarker extends AbstractPoiMarker<int> {
  final int _markerCount;
  final Paint _paint;
  final TextPainter _textPainter;

  /// Constructs a [ClusterMarker].
  ///
  /// [position] The geographical position of the cluster's center.
  /// [markerCount] The number of markers contained within this cluster.
  /// [key] An optional key to uniquely identify this marker.
  ClusterMarker({required ILatLong position, required int markerCount, super.key})
    : _markerCount = markerCount,
      _paint = Paint()..color = Colors.red.shade400,
      _textPainter = TextPainter(textDirection: TextDirection.ltr),
      super(latLong: position);

  String get _clusterText {
    if (_markerCount > 9) {
      return '9+';
    } else {
      return _markerCount.toString();
    }
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) {
    return Future.value();
  }

  @override
  void render(UiRenderContext renderContext) {
    MappointRelative relative = renderContext.projection.latLonToPixel(latLong).offset(renderContext.reference);
    Offset offset = Offset(relative.dx, relative.dy);
    // Draw the circle
    renderContext.canvas.expose().drawCircle(offset, 20, _paint);

    // Prepare the text
    _textPainter.text = TextSpan(
      text: _clusterText,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
    _textPainter.layout();

    // Center the text inside the circle
    final textOffset = offset - Offset(_textPainter.width / 2, _textPainter.height / 2);

    // Draw the text
    _textPainter.paint(renderContext.canvas.expose(), textOffset);
  }

  @override
  MapRectangle? searchForSymbolBoundary(String symbolId) {
    return null;
  }
}
