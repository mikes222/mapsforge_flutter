import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/layer/tilelayer.dart';
import 'package:mapsforge_flutter/model/mapmodel.dart';
import 'package:mapsforge_flutter/model/mappoint.dart';
import 'package:mapsforge_flutter/renderer/tilerendererlayer.dart';

class LayerPainter extends CustomPainter {
  final MapModel mapModel;
  final TileLayer _tileLayer;

  LayerPainter(this.mapModel)
      : assert(mapModel != null),
        _tileLayer = TileRendererLayer(
          tileCache: mapModel.tileCache,
          graphicFactory: mapModel.graphicsFactory,
          displayModel: mapModel.displayModel,
          mapDataStore: mapModel.mapDataStore,
        );

  @override
  void paint(Canvas canvas, Size size) {
    mapModel.mapViewDimension.setDimension(size.width, size.height);
    ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 16.0,
      ),
    )
      ..pushStyle(ui.TextStyle(color: Colors.black45))
      ..addText("hello $size");
    canvas.drawParagraph(
        builder.build()..layout(ui.ParagraphConstraints(width: 200)),
        Offset(0, 0));

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
      canvas.drawParagraph(
          builder.build()..layout(ui.ParagraphConstraints(width: 300)),
          Offset(size.width / 2, size.height / 2));
    } else {
      _tileLayer.draw(
          mapModel.mapViewPosition,
          mapModel.mapDataStore.boundingBox(),
          FlutterCanvas(canvas, size),
          Mappoint(0, 0));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
