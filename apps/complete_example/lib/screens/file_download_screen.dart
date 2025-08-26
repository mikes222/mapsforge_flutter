import 'dart:io';

import 'package:complete_example/models/app_models.dart';
import 'package:complete_example/screens/map_view_screen.dart';
import 'package:complete_example/services/platform_file_download_service.dart';
import 'package:complete_example/widgets/download_location_selector.dart';
import 'package:flutter/foundation.dart';
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
  late final PlatformFileDownloadService _downloadService;
  Future<void>? _downloadFuture;

  int percent = 0;
  String? _downloadPath;
  bool _isDownloadStarted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadService = PlatformFileDownloadService();

    // For web, start download immediately since user interaction is required
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDownload();
      });
    }
  }

  @override
  void dispose() {
    _downloadService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File download'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: _downloadFuture,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.error != null) {
                return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
              }
              return Column(
                children: [
                  _buildMapView(), const SizedBox(height: 16), // Location selector for native platforms
                  if (!kIsWeb && !_isDownloadStarted)
                    DownloadLocationSelector(filename: widget.configuration.location.getLocalfilename(), onLocationSelected: _onLocationSelected),
                  const SizedBox(height: 16),
                  // Download progress
                  if (_isDownloadStarted) ...[
                    LinearProgressIndicator(value: percent / 100.0, minHeight: 16),
                    const SizedBox(height: 8),
                    Text('$percent % completed'),
                  ],

                  // Error message
                  if (_errorMessage != null) ErrorhelperWidget(error: _errorMessage!),

                  if (!kIsWeb && !_isDownloadStarted) _buildStartDownloadButton(),
                  // Web download info
                  if (kIsWeb && !_isDownloadStarted) _buildWebDownloadProgressInfo(),
                  if (percent == 100) _buildNavigateToMapButton(),
                  // Retry button
                  if (_errorMessage != null) _buildRetryButton(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _startDownload() {
    if (_isDownloadStarted) return;

    setState(() {
      _isDownloadStarted = true;
      _errorMessage = null;
      percent = 0;
    });

    _downloadFuture = _downloadMap();
  }

  Future<void> _downloadMap() async {
    try {
      final filename = widget.configuration.location.getLocalfilename();

      await _downloadService.downloadFile(
        url: widget.configuration.location.url,
        filename: filename,
        savePath: _downloadPath,
        onProgress: showDownloadProgress,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb ? 'Download completed! Check your downloads folder.' : 'File saved to: ${_downloadPath ?? filename}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _onLocationSelected(String path) {
    setState(() {
      _downloadPath = path;
      if (File(path).existsSync()) {
        setState(() {
          percent = 100;
          _isDownloadStarted = true;
        });
      }
    });
  }

  void showDownloadProgress(int received, int total) {
    if (total != -1) {
      setState(() {
        percent = (received / total * 100).round();
        //print("$percent %");
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
            const SizedBox(height: 24),
            Icon(Icons.map, size: 120, color: Colors.blue.shade700),
            const SizedBox(height: 24),
            Text(
              'Map View Download',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Please wait until the download is complete',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blue.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStartDownloadButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            onPressed: _downloadPath != null ? _startDownload : null,
            icon: const Icon(Icons.download),
            label: const Text('Start Download'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigateToMapButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MapViewScreen(configuration: widget.configuration, downloadPath: _downloadPath),
                ),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Open Map View'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildWebDownloadProgressInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.info, color: Colors.blue.shade600),
          const SizedBox(height: 8),
          Text(
            'Web Download',
            style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'The file will be downloaded to your browser\'s default download location.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isDownloadStarted = false;
            _errorMessage = null;
            percent = 0;
          });
          _startDownload();
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Retry Download'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
      ),
    );
  }
}
