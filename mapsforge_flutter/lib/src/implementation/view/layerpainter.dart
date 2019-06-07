import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/tilelayer.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

class LayerPainter extends ChangeNotifier implements CustomPainter {
  final MapModel mapModel;
  final TileLayer _tileLayer;

  final MapViewPosition position;

  LayerPainter(this.mapModel, this._tileLayer, this.position)
      : assert(mapModel != null),
        super() {
    _tileLayer.observe.listen((Job job) {
      notifyListeners();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    //mapModel.mapViewDimension.setDimension(size.width, size.height);

    if (position == null || !position.hasPosition()) {
      ui.ParagraphBuilder builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: 16.0,
          textAlign: TextAlign.center,
        ),
      )
        ..pushStyle(ui.TextStyle(
          color: Colors.black45,
        ))
        ..addText("No Position");
      canvas.drawParagraph(builder.build()..layout(ui.ParagraphConstraints(width: 300)), Offset(size.width / 2 - 150, size.height / 2));
    } else {
      bool changed = mapModel.mapViewDimension.setDimension(size.width, size.height);
      if (changed) {
        position.sizeChanged();
      }
      _tileLayer.draw(mapModel.mapViewDimension, position, FlutterCanvas(canvas, size));
    }
  }

  @override
  bool shouldRepaint(LayerPainter oldDelegate) {
    if (oldDelegate?.position != position) return true;
    return false;
  }

  @override
  bool shouldRebuildSemantics(LayerPainter oldDelegate) {
    return false; //super.shouldRebuildSemantics(oldDelegate);
  }

  bool hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;
}
