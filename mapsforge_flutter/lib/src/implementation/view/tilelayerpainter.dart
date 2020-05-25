import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/layer/tilelayer.dart';
import 'package:mapsforge_flutter/src/layer/tilelayerimpl.dart';
import 'package:mapsforge_flutter/src/model/mapviewdimension.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

class TileLayerPainter extends ChangeNotifier implements CustomPainter {
  final MapViewDimension mapViewDimension;
  final TileLayer _tileLayer;

  final MapViewPosition position;

  TileLayerPainter(this.mapViewDimension, this._tileLayer, this.position)
      : assert(mapViewDimension != null),
        assert(position != null);

  @override
  void paint(Canvas canvas, Size size) {
    //mapModel.mapViewDimension.setDimension(size.width, size.height);

    bool changed = mapViewDimension.setDimension(size.width, size.height);
    if (changed) {
      position.sizeChanged();
    }
    _tileLayer.draw(mapViewDimension, position, FlutterCanvas(canvas, size));
  }

  @override
  bool shouldRepaint(TileLayerPainter oldDelegate) {
    if (oldDelegate?.position != position) return true;
    if (_tileLayer.needsRepaint) return true;
    return false;
  }

  @override
  bool shouldRebuildSemantics(TileLayerPainter oldDelegate) {
    return false; //super.shouldRebuildSemantics(oldDelegate);
  }

  bool hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;
}
