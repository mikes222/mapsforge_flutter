import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/view/indoorlevelbar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/subjects.dart';

void main() {
  testWidgets('indoor level bar mapping names', (WidgetTester tester) async {
    final indoorLevelMappings = {
      -2: null,
      2: null,
      1: "OG1",
      3: null,
      0: "EG",
      -1: "UG1"
    };

    // create level bar widget
    await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.rtl,
        child: IndoorLevelBar(
          indoorLevels: indoorLevelMappings,
          onChange: (val) {},
        )));

    // check for all level widgets
    final levelTextFinder = find.byType(Text, skipOffstage: false);
    expect(levelTextFinder, findsNWidgets(indoorLevelMappings.length));

    // check if indoor level mapping names are displayed
    expect(find.text("OG1", skipOffstage: false), findsOneWidget);
    expect(find.text("EG", skipOffstage: false), findsOneWidget);
    expect(find.text("UG1", skipOffstage: false), findsOneWidget);
  });

  testWidgets('indoor level bar sorting', (WidgetTester tester) async {
    final indoorLevelMappings = {
      -2: null,
      2: null,
      1: null,
      3: null,
      0: null,
      -1: null
    };

    // create level bar widget
    await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.rtl,
        child: IndoorLevelBar(
          indoorLevels: indoorLevelMappings,
          onChange: (val) {},
        )));

    // check if levels are sorted correctly
    final levelTextFinder = find.byType(Text, skipOffstage: false);
    final List<Element> levelTextWidgets = levelTextFinder.evaluate().toList();
    int prevLevel =
        int.parse((levelTextWidgets.first.widget as Text).data ?? "");
    for (int i = 1; i < levelTextWidgets.length; i++) {
      int curLevel = int.parse((levelTextWidgets[i].widget as Text).data ?? "");
      expect(prevLevel, greaterThan(curLevel));
      prevLevel = curLevel;
    }
  });
}
