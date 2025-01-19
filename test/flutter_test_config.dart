import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:logging/logging.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  print("Starting testExecutable");
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppFonts();
  _initLogging();
  return testMain();
}

void _initLogging() {
// Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });

// Root logger level.
  Logger.root.level = Level.FINEST;
}
