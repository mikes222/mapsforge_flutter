import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/model/dimension.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

import 'contextmenubuilder.dart';
import 'defaultcontextmenubuilder.dart';

class ContextMenu extends StatefulWidget {
  final TapEvent event;

  final MapModel mapModel;

  final ViewModel viewModel;

  final MapViewPosition position;

  ContextMenuBuilder? contextMenuBuilder;

  ContextMenu(
      {Key? key, required this.event, required this.mapModel, required this.viewModel, required this.position, this.contextMenuBuilder})
      : super(key: key) {
    contextMenuBuilder ??= DefaultContextMenuBuilder();
  }

  @override
  State<StatefulWidget> createState() {
    return ContextMenuState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class ContextMenuState extends State<ContextMenu> implements ContextMenuCallback {
  TapEvent? _lastTapEvent;

  @override
  Widget build(BuildContext context) {
    if (widget.event == _lastTapEvent) return Container();
    widget.position.calculateBoundingBox(widget.viewModel.viewDimension!);
    double x = widget.position.projection!.longitudeToPixelX(widget.event.longitude) - widget.position.leftUpper!.x;
    double y = widget.position.projection!.latitudeToPixelY(widget.event.latitude) - widget.position.leftUpper!.y;
    //x = x + widget.viewOffset.dx;
    //y = y + widget.viewOffset.dy;
    Dimension? screen = widget.viewModel.viewDimension;
    if (x < 0 || y < 0) {
      // out of screen, hide the box
      print("out of screen");
      _lastTapEvent = widget.event;
      return Container();
    }
    return widget.contextMenuBuilder!.build(context, widget.mapModel, widget.viewModel, screen, x, y, widget.event, this);
  }

  @override
  void close(TapEvent event) {
    setState(() {
      _lastTapEvent = event;
    });
  }
}
