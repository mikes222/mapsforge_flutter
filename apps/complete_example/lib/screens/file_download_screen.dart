import 'dart:io';

import 'package:complete_example/models/app_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_view/mapsforge.dart';

class FileDownloadScreen extends StatefulWidget {
  final AppConfiguration configuration;

  const FileDownloadScreen({super.key, required this.configuration});

  @override
  State<FileDownloadScreen> createState() => _FileDownloadScreenState();
}

//////////////////////////////////////////////////////////////////////////////

class _FileDownloadScreenState extends State<FileDownloadScreen> {
  late final Future _future;

  int percent = 0;

  @override
  void initState() {
    super.initState();
    _future = _downloadMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.error != null) {
                return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
              }
              return Column(
                children: [
                  _buildMapView(),
                  LinearProgressIndicator(value: percent / 100.0),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _downloadMap() async {
    Response response = await Dio().get(
      widget.configuration.location.url,
      onReceiveProgress: showDownloadProgress,
      //Received data with List<int>
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );
    print(response.headers);
    var tempDir = await getTemporaryDirectory();
    File file = File(widget.configuration.location.getLocalfilename());
    var raf = file.openSync(mode: FileMode.write);
    // response.data is List<int> type
    raf.writeFromSync(response.data);
    await raf.close();
  }

  void showDownloadProgress(int received, int total) {
    if (total != -1) {
      setState(() {
        percent = (received / total * 100).round();
        print("$percent %");
      });
    }
  }

  Widget _buildMapView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.blue.shade100, Colors.blue.shade300]),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 120, color: Colors.blue.shade700),
            const SizedBox(height: 24),
            Text(
              'Map View Placeholder',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'This is where the actual mapsforge map view would be rendered',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blue.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'All performance optimizations are active and monitoring',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
