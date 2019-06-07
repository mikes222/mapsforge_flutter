import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/view/mapview.dart';

import 'layerpainter.dart';

class FlutterMapView extends StatefulWidget implements MapView {
  final MapModel mapModel;

  const FlutterMapView({
    Key key,
    @required this.mapModel,
  })  : assert(mapModel != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FlutterMapState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _FlutterMapState extends State<FlutterMapView> {
  static final _log = new Logger('_FlutterMapState');

  Mappoint startLeftUpper;

  Offset startOffset;

  @override
  Widget build(BuildContext context) {
    _log.info("draw");
    return Stack(children: <Widget>[
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (DragStartDetails details) {
          startOffset = details.globalPosition;
          startLeftUpper = widget.mapModel.mapViewPosition?.leftUpper;
          print(details.toString());
        },
        onPanUpdate: (DragUpdateDetails details) {
          if (startLeftUpper == null) return;
          print(details.globalPosition.toString() + " / " + details.delta.toString() + " / " + details.primaryDelta.toString());
          widget.mapModel.setLeftUpper(
              startLeftUpper.x + startOffset.dx - details.globalPosition.dx, startLeftUpper.y + startOffset.dy - details.globalPosition.dy);
        },
        onPanEnd: (DragEndDetails details) {
          print(details.toString());
        },
        child: CustomPaint(
          foregroundPainter: LayerPainter(widget.mapModel, widget.mapModel.renderer),
          child: Container(),
        ),
      ),
    ]);
  }
}
