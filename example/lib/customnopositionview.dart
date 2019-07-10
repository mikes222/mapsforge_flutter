import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';

class CustomNoPositionView extends NoPositionView {
  @override
  Widget buildNoPositionView(BuildContext context, MapModel mapModel) {
    return Center(
      child: Text("This is a custom view used when there is no position"),
    );
  }
}
