import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/model/dimension.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';
import 'package:mapsforge_flutter/src/view/defaultcontextmenu.dart';

import 'contextmenubuilder.dart';

class DefaultContextMenuBuilder extends ContextMenuBuilder {
  @override
  Widget buildContextMenu(
      BuildContext context,
      MapModel mapModel,
      ViewModel viewModel,
      MapViewPosition position,
      Dimension screen,
      TapEvent event) {
    return DefaultContextMenu(
      screen: screen,
      event: event,
      viewModel: viewModel,
      mapViewPosition: position,
    );
  }

  const DefaultContextMenuBuilder();
}
