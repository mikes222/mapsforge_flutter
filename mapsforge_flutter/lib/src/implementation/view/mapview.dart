import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
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

  @override
  Widget build(BuildContext context) {
    _log.info("draw");
    return Stack(
      children: <Widget>[
        CustomPaint(
          foregroundPainter: LayerPainter(widget.mapModel, widget.mapModel.renderer),
          child: Container(),
        ),
      ],
    );
  }
}
