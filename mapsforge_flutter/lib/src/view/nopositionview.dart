import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';

class NoPositionView {
  Widget buildNoPositionView(BuildContext context, MapModel mapModel, ViewModel viewModel) {
    return Center(
      child: Text("No Position"),
    );
  }
}
