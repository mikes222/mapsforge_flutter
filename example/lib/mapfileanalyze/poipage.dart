import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/mapreadresult.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';
import 'package:mapsforge_flutter/src/reader/queryparameters.dart';
import 'package:mapsforge_flutter/src/reader/subfileparameter.dart';

class PoiPage extends StatelessWidget {
  /// The read POIs.
  final List<PointOfInterest> pointOfInterests;

  const PoiPage({Key key, this.pointOfInterests}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: pointOfInterests
          .map(
            (e) => Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Layer ${e.layer}, Position ${formatLatLong(e.position)}"),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: e.tags.map((Tag e) => Text("${e.key} = ${e.value}")).toList(),
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
    return "${latLong.latitude?.toStringAsPrecision(6) ?? "Unknown"} / ${latLong.longitude?.toStringAsPrecision(6) ?? "Unknown"}";
  }
}
