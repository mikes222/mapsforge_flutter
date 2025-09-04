import 'package:complete_example/screens/main_navigation_screen.dart';
import 'package:ecache/ecache.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/utils.dart';

void main() {
  _initLogging();
  PerformanceProfiler().setEnabled(true);
  StorageMgr().setEnabled(true);
  runApp(const MapsforgeApp());
}

class MapsforgeApp extends StatelessWidget {
  const MapsforgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapsforge Complete Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: const MainNavigationScreen(),
    );
  }
}

/////////////////////////////////////////////////////////////////////////////

void _initLogging() {
  // Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
