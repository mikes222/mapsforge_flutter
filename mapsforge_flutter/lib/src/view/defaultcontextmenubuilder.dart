import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/model/dimension.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

import 'contextmenubuilder.dart';

class DefaultContextMenuBuilder extends ContextMenuBuilder {
  double outerRadius = 20;
  double width = 4;
  Color borderColor = Colors.green;
  Color backgroundColor = Color(0xc3FFFFFF);

  @override
  Widget build(BuildContext context, MapModel mapModel, ViewModel viewModel, Dimension? screen, double x, double y, TapEvent event,
      ContextMenuCallback callback) {
    Radius outer = Radius.circular(outerRadius);
    Radius inner = Radius.circular(outerRadius - width);
    //print("${x} / ${y}");
    double halfWidth = screen!.width / 2;
    double halfHeight = screen.height / 2;
    return Positioned(
      left: x <= halfWidth ? x : null,
      top: y <= halfHeight ? y : null,
      right: x > halfWidth ? screen.width - x : null,
      bottom: y > halfHeight ? screen.height - y : null,
      child: Container(
        //margin: EdgeInsets.only(left: x, top: y),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: x <= halfWidth && y <= halfHeight ? Radius.zero : outer,
            topRight: x > halfWidth && y <= halfHeight ? Radius.zero : outer,
            bottomLeft: x <= halfWidth && y > halfHeight ? Radius.zero : outer,
            bottomRight: x > halfWidth && y > halfHeight ? Radius.zero : outer,
          ),
          color: borderColor,
        ),
        padding: EdgeInsets.all(width),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: x <= halfWidth && y <= halfHeight ? Radius.zero : inner,
              topRight: x > halfWidth && y <= halfHeight ? Radius.zero : inner,
              bottomLeft: x <= halfWidth && y > halfHeight ? Radius.zero : inner,
              bottomRight: x > halfWidth && y > halfHeight ? Radius.zero : inner,
            ),
            color: backgroundColor,
          ),
          padding: EdgeInsets.only(left: 4, right: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: buildColumns(context, mapModel, viewModel, event, callback),
          ),
        ),
      ),
    );
  }

  List<Widget> buildColumns(BuildContext context, MapModel mapModel, ViewModel viewModel, TapEvent event, ContextMenuCallback callback) {
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            child: Text(
              "${event.latitude.toStringAsFixed(6)} / ${event.longitude.toStringAsFixed(6)}",
              style: TextStyle(fontSize: 12),
            ),
            onLongPress: () {
              Clipboard.setData(new ClipboardData(text: "${event.latitude.toStringAsFixed(6)} / ${event.longitude.toStringAsFixed(6)}"));
            },
          ),
          IconButton(
            padding: EdgeInsets.all(0),
            icon: Icon(Icons.close),
            onPressed: () {
              callback.close(event);
            },
          ),
        ],
      ),
    ];
  }
}
