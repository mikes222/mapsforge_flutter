import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Widget for selecting download location on native platforms
/// On web, this widget is not needed as browser handles download location
class DownloadLocationSelector extends StatefulWidget {
  final String filename;
  final Function(String path) onLocationSelected;
  final String? initialPath;

  const DownloadLocationSelector({super.key, required this.filename, required this.onLocationSelected, this.initialPath});

  @override
  State<DownloadLocationSelector> createState() => _DownloadLocationSelectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _DownloadLocationSelectorState extends State<DownloadLocationSelector> {
  String? _selectedPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.initialPath;
    if (_selectedPath == null) {
      _loadDefaultPath();
    }
  }

  Future<void> _loadDefaultPath() async {
    if (kIsWeb) return;

    setState(() => _isLoading = true);

    try {
      // Try to get a reasonable default directory
      Directory? directory;

      if (Platform.isAndroid) {
        // Try external storage first
        directory = await getTemporaryDirectory(); //Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Desktop platforms
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final fullPath = '${directory.path}/${widget.filename}';
        setState(() => _selectedPath = fullPath);
        widget.onLocationSelected(fullPath);
      }
    } catch (e) {
      // Fallback to temp directory
      final tempDir = await getTemporaryDirectory();
      final fullPath = '${tempDir.path}/${widget.filename}';
      setState(() => _selectedPath = fullPath);
      widget.onLocationSelected(fullPath);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCustomLocation() async {
    if (kIsWeb) return;

    try {
      final result = await FilePicker.platform.saveFile(dialogTitle: 'Select download location', fileName: widget.filename, type: FileType.any);

      if (result != null) {
        setState(() => _selectedPath = result);
        widget.onLocationSelected(result);
      }
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting location: $error'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink(); // Not needed on web
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Download Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_isLoading)
              const Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Loading default location...'),
                ],
              )
            else if (_selectedPath != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected location:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(_selectedPath!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(onPressed: _selectCustomLocation, icon: const Icon(Icons.folder_open), label: const Text('Change Location')),
              ),
            ] else
              const Text('No location selected'),
          ],
        ),
      ),
    );
  }
}
