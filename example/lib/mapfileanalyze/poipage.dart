import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';

class PoiPage extends StatelessWidget {
  /// The read POIs.
  final List<PointOfInterest>? pointOfInterests;

  const PoiPage({Key? key, this.pointOfInterests}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      children: pointOfInterests!
          .map(
            (e) => Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Layer ${e.layer}, Position ${formatLatLong(e.position)}"),
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
