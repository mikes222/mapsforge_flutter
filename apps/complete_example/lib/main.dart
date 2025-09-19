import 'package:complete_example/screens/main_navigation_screen.dart';
import 'package:ecache/ecache.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_core/utils.dart';

void main() {
  _initLogging();
  // enable performance profiling for these classes. Retrieve the results with e.g. PerformanceProfiler().generateReport();
  PerformanceProfiler().setEnabled(true);
  StorageMgr().setEnabled(true);
  TaskQueueMgr().setEnabled(true);
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
