import 'dart:typed_data';

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:mapfile_converter/waycacheproto/cache.pb.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';

class CacheFile {
  int degreeToMicrodegree(double value) {
    return (value * 1e9).round();
  }

  Uint8List toFile(Wayholder wayholder) {
    CacheWayholder cacheWayholder = CacheWayholder();
    cacheWayholder.tileBitmask = wayholder.tileBitmask;
    cacheWayholder.layer = wayholder.layer;
    cacheWayholder.mergedWithOtherWay = wayholder.mergedWithOtherWay;
    if (wayholder.labelPosition != null) {
      CacheLabel cacheLabel = CacheLabel();
      cacheLabel.lat = $fixnum.Int64(degreeToMicrodegree(wayholder.labelPosition!.latitude));
      cacheLabel.lon = $fixnum.Int64(degreeToMicrodegree(wayholder.labelPosition!.longitude));
      cacheWayholder.label = cacheLabel;
    }
    wayholder.tags.forEach((tag) {
      cacheWayholder.tagkeys.add(tag.key!);
      cacheWayholder.tagvals.add(tag.value!);
    });

    for (var innerway in wayholder.innerRead) {
      CacheWay cacheWay = CacheWay();
      for (var point in innerway.path) {
        cacheWay.lat.add($fixnum.Int64(degreeToMicrodegree(point.latitude)));
        cacheWay.lon.add($fixnum.Int64(degreeToMicrodegree(point.longitude)));
      }
      cacheWayholder.innerways.add(cacheWay);
    }
    for (var closedway in wayholder.closedOutersRead) {
      CacheWay cacheWay = CacheWay();
      for (var point in closedway.path) {
        cacheWay.lat.add($fixnum.Int64(degreeToMicrodegree(point.latitude)));
        cacheWay.lon.add($fixnum.Int64(degreeToMicrodegree(point.longitude)));
      }
      cacheWayholder.closedways.add(cacheWay);
    }
    for (var openway in wayholder.openOutersRead) {
      CacheWay cacheWay = CacheWay();
      for (var point in openway.path) {
        cacheWay.lat.add($fixnum.Int64(degreeToMicrodegree(point.latitude)));
        cacheWay.lon.add($fixnum.Int64(degreeToMicrodegree(point.longitude)));
      }
      cacheWayholder.openways.add(cacheWay);
    }
    return cacheWayholder.writeToBuffer();
  }

  Wayholder fromFile(Uint8List file) {
    CacheWayholder cacheWayholder = CacheWayholder.fromBuffer(file);
    Wayholder wayholder = Wayholder();
    wayholder.tileBitmask = cacheWayholder.tileBitmask;
    wayholder.layer = cacheWayholder.layer;
    wayholder.mergedWithOtherWay = cacheWayholder.mergedWithOtherWay;
    if (cacheWayholder.hasLabel()) {
      wayholder.labelPosition = LatLong(cacheWayholder.label.lat.toDouble() / 1e9, cacheWayholder.label.lon.toDouble() / 1e9);
    }
    for (var tagkey in cacheWayholder.tagkeys) {
      wayholder.tags.add(Tag(tagkey, cacheWayholder.tagvals[cacheWayholder.tagkeys.indexOf(tagkey)]));
    }
    for (var action in cacheWayholder.innerways) {
      if (action.lat.isNotEmpty) {
        Waypath waypath = Waypath.empty();
        for (int i = 0; i < action.lat.length; i++) {
          waypath.add(LatLong(action.lat[i].toDouble() / 1e9, action.lon[i].toDouble() / 1e9));
        }
        wayholder.innerWrite.add(waypath);
      }
    }
    for (var action in cacheWayholder.closedways) {
      if (action.lat.isNotEmpty) {
        Waypath waypath = Waypath.empty();
        for (int i = 0; i < action.lat.length; i++) {
          waypath.add(LatLong(action.lat[i].toDouble() / 1e9, action.lon[i].toDouble() / 1e9));
        }
        wayholder.closedOutersWrite.add(waypath);
      }
    }
    for (var action in cacheWayholder.openways) {
      if (action.lat.isNotEmpty) {
        Waypath waypath = Waypath.empty();
        for (int i = 0; i < action.lat.length; i++) {
          waypath.add(LatLong(action.lat[i].toDouble() / 1e9, action.lon[i].toDouble() / 1e9));
        }
        wayholder.openOutersWrite.add(waypath);
      }
    }
    return wayholder;
  }
}
