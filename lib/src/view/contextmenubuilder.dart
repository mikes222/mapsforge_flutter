import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';

/// A builder for contextmenus. These will be activated if a user single-taps
/// at the map. The position of the tap will be given by [event].
/// See also [DefaultContextMenuBuilder].
abstract class ContextMenuBuilder {
  /// Createa a contextmenu
  Widget buildContextMenu(
      BuildContext context,
      MapModel mapModel,
      ViewModel viewModel,
      MapViewPosition position,
      Dimension screen,
      TapEvent event);

  const ContextMenuBuilder();
}
