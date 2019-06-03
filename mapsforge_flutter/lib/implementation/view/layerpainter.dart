import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/layer/job/jobrenderer.dart';
import 'package:mapsforge_flutter/layer/tilelayer.dart';
import 'package:mapsforge_flutter/model/mapmodel.dart';

class LayerPainter extends ChangeNotifier implements CustomPainter {
  final MapModel mapModel;
  final TileLayer _tileLayer;

  LayerPainter(this.mapModel, JobRenderer jobRenderer)
      : assert(mapModel != null),
        _tileLayer = TileLayer(
          tileCache: mapModel.tileCache,
          displayModel: mapModel.displayModel,
          jobRenderer: jobRenderer,
        ),
        super() {
    _tileLayer.observe.listen((job) {
      notifyListeners();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    //mapModel.mapViewDimension.setDimension(size.width, size.height);

    if (mapModel.mapViewPosition == null) {
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
      mapModel.mapViewPosition.setSize(size);
      _tileLayer.draw(mapModel.mapViewPosition, FlutterCanvas(canvas, size));
    }
  }

  @override
  bool shouldRepaint(LayerPainter oldDelegate) {
    if (oldDelegate?.mapModel?.mapViewPosition != mapModel.mapViewPosition) return true;
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
