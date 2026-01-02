import 'dart:io';

import 'package:mapfile_converter/modifiers/poiholder_file_collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:test/test.dart';

void main() {
  test('PoiholderFileCollection swaps to disk and preserves order', () async {
    final tmpDir = Directory.systemTemp.createTempSync('poiholder_file_collection_test_');
    final file = File('${tmpDir.path}${Platform.pathSeparator}pois.tmp');

    PoiholderFileCollection coll = PoiholderFileCollection(filename: file.path);

    for (int i = 0; i < 10; i++) {
      coll.add(Poiholder(position: LatLong(i.toDouble(), (i + 100).toDouble()), tagholderCollection: TagholderCollection.fromPoi({'name': 'poi_$i'})));
    }

    expect(coll.length, 10);

    final seen = <String>[];
    await coll.forEach((p) {
      seen.add('${p.latitude},${p.longitude},${p.tagholderCollection.getTag('name')}');
    });

    expect(seen.length, 10);
    for (int i = 0; i < 10; i++) {
      expect(seen[i], '${i.toDouble()},${(i + 100).toDouble()},poi_$i');
    }

    final p7 = await coll.get(7);
    expect(p7.latitude, 7);
    expect(p7.longitude, 107);
    expect(p7.tagholderCollection.getTag('name'), 'poi_7');

    await coll.dispose();
    expect(file.existsSync(), isFalse);

    tmpDir.deleteSync(recursive: true);
  });

  test('PoiholderFileCollection removeWhere removes matching entries and preserves order', () async {
    final tmpDir = Directory.systemTemp.createTempSync('poiholder_file_collection_remove_test_');
    final file = File('${tmpDir.path}${Platform.pathSeparator}pois.tmp');

    PoiholderFileCollection coll = PoiholderFileCollection(filename: file.path);

    for (int i = 0; i < 10; i++) {
      coll.add(Poiholder(position: LatLong(i.toDouble(), (i + 100).toDouble()), tagholderCollection: TagholderCollection.fromPoi({'name': 'poi_$i'})));
    }

    await coll.removeWhere((p) => p.latitude.toInt().isEven);

    expect(coll.length, 5);

    final seen = <String>[];
    await coll.forEach((p) {
      seen.add('${p.latitude},${p.longitude},${p.tagholderCollection.getTag('name')}');
    });

    expect(seen.length, 5);
    for (int i = 0; i < 5; i++) {
      final original = (i * 2) + 1;
      expect(seen[i], '${original.toDouble()},${(original + 100).toDouble()},poi_$original');
    }

    final p3 = await coll.get(1);
    expect(p3.latitude, 3);
    expect(p3.longitude, 103);
    expect(p3.tagholderCollection.getTag('name'), 'poi_3');

    final iterSeen = <String>[];
    await for (final p in coll.iterator) {
      iterSeen.add('${p.latitude},${p.longitude},${p.tagholderCollection.getTag('name')}');
    }
    expect(iterSeen, seen);

    final all = await coll.getAll();
    final allSeen = all.map((p) => '${p.latitude},${p.longitude},${p.tagholderCollection.getTag('name')}').toList();
    expect(allSeen, seen);

    await coll.dispose();
    expect(file.existsSync(), isFalse);

    tmpDir.deleteSync(recursive: true);
  });

  test('PoiholderFileCollection mergeFrom merges two collections', () async {
    final tmpDir = Directory.systemTemp.createTempSync('poiholder_file_collection_merge_test_');
    final fileA = File('${tmpDir.path}${Platform.pathSeparator}pois_a.tmp');
    final fileB = File('${tmpDir.path}${Platform.pathSeparator}pois_b.tmp');

    final a = PoiholderFileCollection(filename: fileA.path);
    final b = PoiholderFileCollection(filename: fileB.path);

    for (int i = 0; i < 10; i++) {
      a.add(Poiholder(position: LatLong(i.toDouble(), (i + 100).toDouble()), tagholderCollection: TagholderCollection.fromPoi({'name': 'a_$i'})));
    }

    for (int i = 0; i < 10; i++) {
      b.add(Poiholder(position: LatLong((i + 1000).toDouble(), (i + 2000).toDouble()), tagholderCollection: TagholderCollection.fromPoi({'name': 'b_$i'})));
    }

    await a.mergeFrom(b);

    expect(a.length, 20);

    final names = <String>{};
    await for (final p in a.iterator) {
      names.add(p.tagholderCollection.getTag('name')!);
    }

    for (int i = 0; i < 10; i++) {
      expect(names.contains('a_$i'), isTrue);
      expect(names.contains('b_$i'), isTrue);
    }

    await a.dispose();
    await b.dispose();

    expect(fileA.existsSync(), isFalse);
    expect(fileB.existsSync(), isFalse);

    tmpDir.deleteSync(recursive: true);
  });

  test('PoiholderFileCollection addAll batches disk writes', () async {
    final tmpDir = Directory.systemTemp.createTempSync('poiholder_file_collection_addall_test_');
    final file = File('${tmpDir.path}${Platform.pathSeparator}pois.tmp');

    final coll = PoiholderFileCollection(filename: file.path);

    final items = List.generate(
      25,
      (i) => Poiholder(position: LatLong(i.toDouble(), (i + 100).toDouble()), tagholderCollection: TagholderCollection.fromPoi({'name': 'poi_$i'})),
    );

    coll.addAll(items);

    expect(coll.length, 25);

    final names = <String>{};
    await coll.forEach((p) {
      names.add(p.tagholderCollection.getTag('name')!);
    });

    for (int i = 0; i < 25; i++) {
      expect(names.contains('poi_$i'), isTrue);
    }

    await coll.dispose();
    expect(file.existsSync(), isFalse);
    tmpDir.deleteSync(recursive: true);
  });
}
