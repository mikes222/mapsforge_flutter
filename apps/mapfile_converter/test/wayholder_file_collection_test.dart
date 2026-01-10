import 'dart:io';

import 'package:mapfile_converter/modifiers/wayholder_file_collection.dart';
import 'package:mapfile_converter/modifiers/wayholder_id_file_collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:test/test.dart';

Waypath _square(double minLat, double minLon, double maxLat, double maxLon) {
  return Waypath(path: [LatLong(maxLat, minLon), LatLong(maxLat, maxLon), LatLong(minLat, maxLon), LatLong(minLat, minLon), LatLong(maxLat, minLon)]);
}

Wayholder _bigWayholder(int i) {
  final w = Wayholder(tagholderCollection: TagholderCollection.fromWay({'name': 'way_$i'}));
  // 6 points => nodeCount() > 5 so it will be considered "large" and spilled.
  w.closedOutersAdd(Waypath(path: [LatLong(0, 0), LatLong(0, 1), LatLong(1, 1), LatLong(1, 0), LatLong(0, 0), LatLong(0, 0.5), LatLong(0, 0)]));
  return w;
}

void main() {
  test('WayholderFileCollection addAll batches spilling to disk (1000 ways at once)', () async {
    final tmpDir = Directory.systemTemp.createTempSync('wayholder_list_file_collection_test_');
    final file = File('${tmpDir.path}${Platform.pathSeparator}ways_list.tmp');

    final coll = WayholderFileCollection(filename: file.path);

    final items = List.generate(1000, (i) => _bigWayholder(i));
    coll.addAll(items);

    expect(coll.length, 1000);
    // Disk flush should have happened.
    expect(file.existsSync(), isTrue);

    // final w123 = await coll.get(123);
    // expect(w123.tagholderCollection.getTag('name'), 'way_123');

    await coll.dispose();
    for (int i = 0; i < 50 && file.existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(file.existsSync(), isFalse);

    tmpDir.deleteSync(recursive: true);
  });

  test('WayholderFileCollection mergeFrom(WayholderIdFileCollection) merges all wayholders', () async {
    final tmpDir = Directory.systemTemp.createTempSync('wayholder_list_merge_from_id_test_');
    final fileList = File('${tmpDir.path}${Platform.pathSeparator}ways_list.tmp');
    final fileId = File('${tmpDir.path}${Platform.pathSeparator}ways_id.tmp');

    final listColl = WayholderFileCollection(filename: fileList.path);
    final idColl = WayholderIdFileCollection(filename: fileId.path);

    // Make sure we hit both pending (not flushed) and flushed cases.
    for (int i = 0; i < 1005; i++) {
      idColl.add(i, _bigWayholder(i));
    }

    await listColl.mergeFrom(idColl);
    expect(listColl.length, 1005);

    // final all = await listColl.getAll();
    // expect(all.length, 1005);
    //
    // // Since ids are discarded, we just verify all tag names exist.
    // final names = all.map((w) => w.tagholderCollection.getTag('name')!).toSet();
    // for (int i = 0; i < 1005; i++) {
    //   expect(names.contains('way_$i'), isTrue);
    // }

    await listColl.dispose();
    idColl.dispose();

    for (int i = 0; i < 50 && (fileList.existsSync() || fileId.existsSync()); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(fileList.existsSync(), isFalse);
    expect(fileId.existsSync(), isFalse);

    tmpDir.deleteSync(recursive: true);
  });

  test('WayholderFileCollection batches spilling to disk (1000 ways at once)', () async {
    final tmpDir = Directory.systemTemp.createTempSync('wayholder_file_collection_test_');
    final file = File('${tmpDir.path}${Platform.pathSeparator}ways.tmp');

    final coll = WayholderIdFileCollection(filename: file.path);

    // Add 999 large ways - should still be pending (not flushed).
    for (int i = 0; i < 999; i++) {
      coll.add(i, _bigWayholder(i));
    }

    expect(coll.length, 999);
    expect(file.existsSync(), isFalse);

    // Access an element before flush (must be retrievable from pending in-memory spill buffer)
    // final w10 = await coll.get(10);
    // expect(w10.tagholderCollection.getTag('name'), 'way_10');

    // Add one more to reach 1000 => should flush to disk.
    coll.add(999, _bigWayholder(999));
    expect(coll.length, 1000);

    // Force any pending IO buffers to be visible.
    // final w999 = await coll.get(999);
    // expect(w999.tagholderCollection.getTag('name'), 'way_999');

    expect(file.existsSync(), isTrue);

    coll.dispose();
    // dispose deletes file async (close().then). Give it a moment by polling.
    for (int i = 0; i < 50 && file.existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(file.existsSync(), isFalse);

    tmpDir.deleteSync(recursive: true);
  });

  test('WayholderFileCollection mergeFrom merges pending and flushed ways', () async {
    final tmpDir = Directory.systemTemp.createTempSync('wayholder_file_collection_merge_test_');
    final fileA = File('${tmpDir.path}${Platform.pathSeparator}ways_a.tmp');
    final fileB = File('${tmpDir.path}${Platform.pathSeparator}ways_b.tmp');

    final a = WayholderIdFileCollection(filename: fileA.path);
    final b = WayholderIdFileCollection(filename: fileB.path);

    // A: pending (not yet flushed)
    for (int i = 0; i < 10; i++) {
      a.add(i, _bigWayholder(i));
    }

    // B: flushed (1000 triggers flush)
    for (int i = 1000; i < 2000; i++) {
      b.add(i, _bigWayholder(i));
    }

    expect(fileA.existsSync(), isFalse);
    expect(fileB.existsSync(), isTrue);

    await a.mergeFrom(b);

    expect(a.length, 1010);

    // final w5 = await a.get(5);
    // expect(w5.tagholderCollection.getTag('name'), 'way_5');
    //
    // final w1500 = await a.get(1500);
    // expect(w1500.tagholderCollection.getTag('name'), 'way_1500');
    //
    // // Ensure some random ids exist
    // for (final id in [0, 9, 1000, 1500, 1999]) {
    //   final w = await a.get(id);
    //   expect(w.tagholderCollection.getTag('name'), 'way_$id');
    // }

    a.dispose();
    b.dispose();

    for (int i = 0; i < 50 && (fileA.existsSync() || fileB.existsSync()); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(fileA.existsSync(), isFalse);
    expect(fileB.existsSync(), isFalse);

    tmpDir.deleteSync(recursive: true);
  });
}
