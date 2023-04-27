import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestHelper {
  static Future<void> pumpWidget(
      {required WidgetTester tester,
      required Widget child,
      required String goldenfile}) async {
    Key key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          appBar: AppBar(title: Text(child.runtimeType.toString())),
          body: Center(
            child: Container(
              key: key,
              decoration: BoxDecoration(
                  border: Border.all(width: 2, color: Colors.blue)),
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byKey(key), matchesGoldenFile(goldenfile));
  }
}
