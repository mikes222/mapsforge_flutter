import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';

class NoPositionOverlay extends StatelessWidget {
  final MapModel mapModel;

  const NoPositionOverlay({super.key, required this.mapModel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: mapModel.positionStream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.error != null) {
          return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
        }
        if (snapshot.data != null) return const SizedBox();
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 30,
            children: [
              Text("No location information available", style: Theme.of(context).textTheme.headlineMedium),
              Icon(Icons.gpp_bad_outlined, size: 100, color: Theme.of(context).colorScheme.error),
            ],
          ),
        );
      },
    );
  }
}
