// lib/src/camera/map_scene_view.dart
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/overlay.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter_core/utils.dart';

class MapSceneView extends StatefulWidget {
  final MapCamera camera;
  final TileEngine tiles;
  final List<MapLayer> layers;

  const MapSceneView({
    super.key,
    required this.camera,
    required this.tiles,
    required this.layers,
  });

  @override
  State<MapSceneView> createState() => _MapSceneViewState();
}

class _MapSceneViewState extends State<MapSceneView> {
  late List<MapLayer> _layers; // owned/attached instances
  late Listenable _repaint; // merged listenable

  @override
  void initState() {
    super.initState();
    _layers = [];
    _attachNewLayers(widget.layers);
    _rebuildRepaint();
  }

  @override
  void didUpdateWidget(covariant MapSceneView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detach layers that disappeared
    for (final old in _layers.toList()) {
      if (!widget.layers.contains(old)) {
        _detachLayer(old);
        _layers.remove(old);
      }
    }

    // Attach any new instances first
    _attachNewLayers(widget.layers.where((l) => !_layers.contains(l)));

    // Now (re)build the merged repaint
    _rebuildRepaint();
  }

  void _attachNewLayers(Iterable<MapLayer> incoming) {
    for (final layer in incoming) {
      if (!_layers.contains(layer)) {
        layer.attach(
          camera: widget.camera,
        ); // sets _camera before any notifications are observed
        _layers.add(layer);
      }
    }
    _layers.sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  void _detachLayer(MapLayer layer) {
    try {
      layer.detach();
    } catch (_) {}
  }

  void _rebuildRepaint() {
    _repaint = Listenable.merge([widget.camera, widget.tiles, ..._layers]);
  }

  @override
  void dispose() {
    for (final l in _layers) {
      _detachLayer(l);
      l.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // viewport sync
        widget.camera.setViewport(constraints.biggest);
        final scale = MapsforgeSettingsMgr().getDeviceScaleFactor();
        widget.tiles.setViewport(constraints.biggest, scale);

        final pos = widget.camera.position;

        return TransformWidget(
          mapCenter: pos.getCenter(),
          mapPosition: pos,
          screensize: constraints.biggest,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _LayersPainter(repaint: _repaint, layers: _layers),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _LayersPainter extends CustomPainter {
  final List<MapLayer> layers;
  _LayersPainter({required Listenable repaint, required this.layers})
    : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      // Extra safety: skip if somehow not attached
      if (!layer.isAttached) continue;
      layer.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(_LayersPainter oldDelegate) => true;
}
