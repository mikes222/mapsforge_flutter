import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/model/mapmodel.dart';
import 'package:mapsforge_flutter/view/mapview.dart';

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
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        CustomPaint(
          foregroundPainter: LayerPainter(widget.mapModel),
          child: Container(),
        ),
      ],
    );
  }
}
