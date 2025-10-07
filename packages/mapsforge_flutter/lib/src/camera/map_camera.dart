import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:mapsforge_flutter/mapsforge.dart';

class MapCamera extends ChangeNotifier {
  final MapModel mapModel;
  late final StreamSubscription<MapPosition> _sub;

  MapPosition _position;
  Size _viewport = Size.zero;

  /// Pass an explicit initial MapPosition.
  MapCamera({required this.mapModel, required MapPosition initialPosition})
    : _position = initialPosition {
    _sub = mapModel.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
  }

  MapPosition get position => _position;
  Size get viewport => _viewport;

  void setViewport(Size v) {
    if (v != _viewport) {
      _viewport = v;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
