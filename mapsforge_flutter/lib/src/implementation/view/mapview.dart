import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/layer/tilelayer.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/view/mapview.dart';

import '../../../core.dart';
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

  TileLayer _tileLayer;

  MapViewPosition _position;

  @override
  void initState() {
    super.initState();
    _tileLayer = TileLayer(
      tileCache: widget.mapModel.tileCache,
      displayModel: widget.mapModel.displayModel,
      jobRenderer: widget.mapModel.renderer,
    );
    widget.mapModel.observe.listen((MapViewPosition position) {
      setState(() {
        _position = position;
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log.info("draw");
    return Stack(children: <Widget>[
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: () {
          widget.mapModel.zoomIn();
        },
        onScaleStart: (ScaleStartDetails details) {
          startOffset = details.focalPoint;
          startLeftUpper = widget.mapModel.mapViewPosition?.leftUpper;
          print(details.toString());
        },
        onScaleUpdate: (ScaleUpdateDetails details) {
          if (startLeftUpper == null) return;
          if (details.scale == 1) {
            widget.mapModel.setLeftUpper(
                startLeftUpper.x + startOffset.dx - details.focalPoint.dx, startLeftUpper.y + startOffset.dy - details.focalPoint.dy);
          } else {
            print(details.toString());
          }
        },
        onScaleEnd: (ScaleEndDetails details) {
          print(details.toString());
        },
        child: CustomPaint(
          foregroundPainter: LayerPainter(widget.mapModel, _tileLayer, _position),
          child: Container(),
        ),
      ),
    ]);
  }
}
