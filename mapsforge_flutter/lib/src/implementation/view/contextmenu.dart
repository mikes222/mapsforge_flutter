import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/utils/mercatorprojection.dart';

class ContextMenu extends StatefulWidget {
  final TapEvent event;

  final MapModel mapModel;

  final MapViewPosition position;

  final Offset viewOffset;

  const ContextMenu({Key key, @required this.event, @required this.mapModel, @required this.position, @required this.viewOffset})
      : assert(event != null),
        assert(mapModel != null),
        assert(position != null),
        assert(viewOffset != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ContextMenuState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class ContextMenuState extends State<ContextMenu> {
  TapEvent _lastTapEvent;

  @override
  Widget build(BuildContext context) {
    if (widget.event == _lastTapEvent) return Container();
    widget.position.calculateBoundingBox(widget.mapModel.displayModel.tileSize, widget.mapModel.mapViewDimension.getDimension());
    double x =
        MercatorProjection.longitudeToPixelX(widget.event.longitude, widget.position.zoomLevel, widget.mapModel.displayModel.tileSize) -
            widget.position.leftUpper.x;
    double y =
        MercatorProjection.latitudeToPixelY(widget.event.latitude, widget.position.zoomLevel, widget.mapModel.displayModel.tileSize) -
            widget.position.leftUpper.y;
    x = x - widget.viewOffset.dx;
    y = y - widget.viewOffset.dy;
    if (x < 0 || y < 0) {
      // out of screen, hide the box
      print("out of screen");
      _lastTapEvent = widget.event;
      return Container();
    }
    //print("${x} / ${y}");
    return Container(
      margin: EdgeInsets.only(left: x, top: y),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topRight: Radius.circular(14), bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
        color: Colors.black54,
      ),
      padding: EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
          color: Color(0xc3FFFFFF),
        ),
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text("${widget.event.latitude.toStringAsFixed(6)} / ${widget.event.longitude.toStringAsFixed(6)}"),
                IconButton(
                  padding: EdgeInsets.all(0),
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _lastTapEvent = widget.event;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
