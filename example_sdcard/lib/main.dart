import 'package:example_sdcard/uilayer/download_map.dart';
import 'package:example_sdcard/uilayer/existing_map.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage());
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick an Example'),
      ),
      body: ListView(
        children: [
          Card(
            elevation: 4,
            child: ListTile(
              title: const Text('Download map of Monaco to sdcard'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DownloadMap()),
              ),
              trailing: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
          Card(
            elevation: 4,
            child: ListTile(
              title: const Text('Pick an existing Map from sdcard'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExistingMap()),
              ),
              trailing: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
          Card(
            elevation: 4,
            child: ListTile(
              title: const Text('Reset and start afresh'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();

                final downloadedFileUri = prefs.getString('downloadedMapUriString');

                if (downloadedFileUri != null) {
                  final storageHandlder = MapsforgeStorage(mapUriString: downloadedFileUri);
                  storageHandlder.deleteMap();
                }
                
                await prefs.remove('existingMapUriString');
                await prefs.remove('downloadedMapUriString');
              },
            ),
          ),
        ],
      ),
    );
  }
}
