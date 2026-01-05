import 'dart:math';

import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class HolderCollectionFactory {
  static HolderCollectionFactory? _instance;

  static int randomId = Random().nextInt(1000000000);

  HolderCollectionImplementation _implementation = HolderCollectionImplementation();

  HolderCollectionFactory._();

  factory HolderCollectionFactory() {
    if (_instance != null) return _instance!;
    _instance = HolderCollectionFactory._();
    return _instance!;
  }

  void setImplementation(HolderCollectionImplementation implementation) {
    _implementation = implementation;
  }

  IPoiholderCollection createPoiholderCollection(String prefix) {
    return _implementation.createPoiholderCollection(prefix);
  }

  IWayholderCollection createWayholderCollection(String prefix) {
    return _implementation.createWayholderCollection(prefix);
  }
}

//////////////////////////////////////////////////////////////////////////////

class HolderCollectionImplementation {
  IPoiholderCollection createPoiholderCollection(String prefix) {
    return PoiholderCollection();
  }

  IWayholderCollection createWayholderCollection(String prefix) {
    return WayholderCollection();
  }
}

//////////////////////////////////////////////////////////////////////////////
