import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';

class DefaultContextMenu extends StatefulWidget {
  /// The dimensions of the map
  final Dimension screen;

  /// The event when the context menu have been requested.
  final TapEvent event;

  final ViewModel viewModel;

  /// The current position of the map. Note that the map could move even if the contextmenu is shown.
  /// This means the x/y coordinates of the [event] may not be accurate anymore. The lat/lon
  /// position also represents the CURRENT position and not the position when the tap event occured.
  final MapViewPosition position;

  DefaultContextMenu(
      {required this.screen,
      required this.event,
      required this.viewModel,
      required this.position});

  @override
  State<StatefulWidget> createState() {
    return DefaultContextMenuState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class DefaultContextMenuState extends State {
  double outerRadius = 20;
  double width = 4;
  double padding = 16;
  Color borderColor = Colors.green;
  Color backgroundColor = const Color(0xc3FFFFFF);

  @override
  DefaultContextMenu get widget => super.widget as DefaultContextMenu;

  @override
  Widget build(BuildContext context) {
    setValues(context);
    Radius outer = Radius.circular(outerRadius);
    // x and y of the event stays the same but we want our contextmenu to move with the map so calculate the
    // newest x/y coordinates based on the current position
    // double x = widget.event.x;
    // double y = widget.event.y;

    widget.position.calculateBoundingBox(widget.viewModel.viewDimension!);
    double x =
        widget.position.projection!.longitudeToPixelX(widget.event.longitude) -
            widget.position.leftUpper!.x;
    double y =
        widget.position.projection!.latitudeToPixelY(widget.event.latitude) -
            widget.position.leftUpper!.y;

    double halfWidth = widget.screen.width / 2;
    double halfHeight = widget.screen.height / 2;
    return Positioned(
      left: x <= halfWidth ? x : null,
      top: y <= halfHeight ? y : null,
      right: x > halfWidth ? widget.screen.width - x : null,
      bottom: y > halfHeight ? widget.screen.height - y : null,
      child: Container(
        //margin: EdgeInsets.only(left: x, top: y),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: x <= halfWidth && y <= halfHeight ? Radius.zero : outer,
            topRight: x > halfWidth && y <= halfHeight ? Radius.zero : outer,
            bottomLeft: x <= halfWidth && y > halfHeight ? Radius.zero : outer,
            bottomRight: x > halfWidth && y > halfHeight ? Radius.zero : outer,
          ),
          color: backgroundColor,
          border: Border.all(color: borderColor, width: width),
        ),
        padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: buildColumns(context),
        ),
      ),
    );
  }

  void setValues(BuildContext context) {
    backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    borderColor = Theme.of(context).primaryColor;
  }

  List<Widget> buildColumns(BuildContext context) {
    return [
      Row(
        //mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            child: Text(
              "${widget.event.latitude.toStringAsFixed(6)} / ${widget.event.longitude.toStringAsFixed(6)}",
              style: const TextStyle(fontSize: 14),
            ),
            onLongPress: () {
              Clipboard.setData(new ClipboardData(
                  text:
                      "${widget.event.latitude.toStringAsFixed(6)} / ${widget.event.longitude.toStringAsFixed(6)}"));
            },
          ),
          //const Spacer(),
          // todo move the close icon to the right side
          IconButton(
            padding: const EdgeInsets.all(0),
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.viewModel.clearTapEvent();
            },
          ),
        ],
      ),
    ];
  }
}
