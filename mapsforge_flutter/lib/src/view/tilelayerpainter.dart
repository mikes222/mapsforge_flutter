import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:mapsforge_flutter/src/layer/tilelayer.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

class TileLayerPainter extends CustomPainter {
  final TileLayer _tileLayer;

  final MapViewPosition position;

  final ViewModel viewModel;

  final JobSet jobSet;

  TileLayerPainter(this._tileLayer, this.position, this.viewModel, this.jobSet)
      : super(repaint: jobSet);

  @override
  void paint(Canvas canvas, Size size) {
    //viewModel.setViewDimension(size.width, size.height);
    _tileLayer.draw(viewModel, position, FlutterCanvas(canvas, size), jobSet);
  }

  @override
  bool shouldRepaint(TileLayerPainter oldDelegate) {
    if (oldDelegate.position != position) return true;
    if (_tileLayer.needsRepaint) return true;
    return false;
  }

  @override
  bool shouldRebuildSemantics(TileLayerPainter oldDelegate) {
    return false; //super.shouldRebuildSemantics(oldDelegate);
  }

  @override
  bool? hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;
}
