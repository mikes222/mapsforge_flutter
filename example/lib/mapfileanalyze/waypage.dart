import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/way.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';

class WayPage extends StatelessWidget {
  /// The read POIs.
  final List<Way>? ways;

  const WayPage({Key? key, this.ways}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      children: ways!
          .map(
            (e) => Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Layer ${e.layer}, labelPosition ${e.labelPosition}, ${e.latLongs.length} coordinate with ${e.latLongs[0].length} segments in coordinate 0"),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: e.tags
                        .map((Tag e) => Text("${e.key} = ${e.value}"))
                        .toList(),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String formatLatLong(ILatLong latLong) {
    if (latLong == null) return "Unknown";
    return "${latLong.latitude.toStringAsPrecision(6)} / ${latLong.longitude.toStringAsPrecision(6)}";
  }
}
