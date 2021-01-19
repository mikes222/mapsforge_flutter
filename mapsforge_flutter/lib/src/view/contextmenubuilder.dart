import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/model/dimension.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

abstract class ContextMenuBuilder {
  Widget build(BuildContext context, MapModel mapModel, Dimension screen, double x, double y, TapEvent event, ContextMenuCallback callback);
}

/////////////////////////////////////////////////////////////////////////////

abstract class ContextMenuCallback {
  void close(TapEvent event);
}
