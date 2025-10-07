// lib/src/camera/map_layer.dart
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/overlay.dart';

abstract class MapLayer extends ChangeNotifier {
  int get zIndex => 0;

  MapCamera? _camera;
  bool get isAttached => _camera != null;
  MapCamera get camera {
    assert(_camera != null, 'MapLayer.paint() used before attach()');
    return _camera!;
  }

  @mustCallSuper
  void attach({required MapCamera camera}) {
    _camera = camera;
  }

  @mustCallSuper
  void detach() {
    _camera = null;
  }

  void paint(Canvas canvas, Size size);
}
