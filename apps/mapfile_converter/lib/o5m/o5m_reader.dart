import 'dart:convert';
import 'dart:io';

import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapfile_converter/pbf/pbf_reader.dart';
import 'package:mapsforge_flutter_core/model.dart';

class O5mReader implements IPbfReader {
  static const int _stringTableSize = 15000;

  final RandomAccessFile _raf;
  final int _sourceLength;

  BoundingBox? _boundingBox;

  final Map<int, OsmNode> _nodes = {};
  final Map<int, OsmWay> _ways = {};
  final Map<int, OsmRelation> _relations = {};

  int _idDelta = 0;
  int _wayIdDelta = 0;
  int _relIdDelta = 0;

  int _nodeLonDelta = 0; // 100-nanodegree
  int _nodeLatDelta = 0; // 100-nanodegree

  final List<_StringPair?> _stringTable = List<_StringPair?>.filled(_stringTableSize, null, growable: false);
  int _stringTablePos = 0;
  int _stringTableCount = 0;

  bool _eof = false;

  O5mReader._(this._raf, this._sourceLength);

  static Future<O5mReader> open(String filePath) async {
    final file = File(filePath);
    final raf = await file.open();
    final len = await file.length();
    return O5mReader._(raf, len);
  }

  @override
  void dispose() {
    _nodes.clear();
    _ways.clear();
    _relations.clear();
    _raf.closeSync();
  }

  @override
  Future<OsmData?> readBlobData(int position) async {
    await _raf.setPosition(position);
    _eof = false;
    return _readNextBatch();
  }

  @override
  Future<OsmData?> readNextBlobData() async {
    return _readNextBatch();
  }

  @override
  Future<BoundingBox?> calculateBounds() async {
    return _boundingBox;
  }

  @override
  Future<List<int>> getBlobPositions() {
    throw UnimplementedError();
  }

  Future<OsmData?> _readNextBatch() async {
    if (_eof) return null;

    while (true) {
      final pos = await _raf.position();
      if (pos >= _sourceLength) {
        _eof = true;
        return _sendData(force: true);
      }

      final first = await _raf.readByte();
      if (first == -1) {
        _eof = true;
        return _sendData(force: true);
      }

      final b = first & 0xFF;
      if (b == 0xFF) {
        _resetDeltas();
        continue;
      }
      if (b == 0xFE) {
        _eof = true;
        return _sendData(force: true);
      }

      if (b == 0xEE || b == 0xEF) {
        // Sync / Jump have a length field.
        final len = await _readUnsigned();
        await _raf.setPosition((await _raf.position()) + len);
        continue;
      }

      if (b == 0xE0) {
        final len = await _readUnsigned();
        await _raf.setPosition((await _raf.position()) + len);
        continue;
      }

      if (b == 0xDC) {
        // file timestamp: signed
        final len = await _readUnsigned();
        await _raf.setPosition((await _raf.position()) + len);
        continue;
      }

      if (b == 0xDB) {
        final len = await _readUnsigned();
        final data = await _raf.read(len);
        _parseBoundingBox(data);
        continue;
      }

      if (b == 0x10 || b == 0x11 || b == 0x12) {
        final len = await _readUnsigned();
        final data = await _raf.read(len);
        if (b == 0x10) {
          _parseNode(data);
        } else if (b == 0x11) {
          _parseWay(data);
        } else {
          _parseRelation(data);
        }

        final osmData = _sendData(force: false);
        if (osmData != null) return osmData;
        continue;
      }

      // Unknown dataset with length.
      if (b < 0xF0) {
        final len = await _readUnsigned();
        await _raf.setPosition((await _raf.position()) + len);
        continue;
      }

      // Unknown single-byte command in 0xF0..0xFF range.
    }
  }

  void _parseBoundingBox(List<int> data) {
    final r = _O5mByteReader(data);
    final x1 = r.readSigned();
    final y1 = r.readSigned();
    final x2 = r.readSigned();
    final y2 = r.readSigned();
    _boundingBox = BoundingBox(y1 * 1e-7, x1 * 1e-7, y2 * 1e-7, x2 * 1e-7);
  }

  void _parseNode(List<int> data) {
    final r = _O5mByteReader(data);
    _idDelta += r.readSigned();

    _skipVersionInfoIfPresent(r);

    final lonDelta = r.readSigned();
    final latDelta = r.readSigned();

    // longitude deltas are expected to be in 32-bit signed arithmetic.
    _nodeLonDelta = (_nodeLonDelta + lonDelta).toSigned(32);
    _nodeLatDelta += latDelta;

    final tags = _readTags(r);

    final latNano = _nodeLatDelta * 100;
    final lonNano = _nodeLonDelta * 100;

    _nodes[_idDelta] = OsmNode(
      id: _idDelta,
      tags: tags,
      latLong: NanoLatLong.fromNano(latNano, lonNano),
    );
  }

  void _parseWay(List<int> data) {
    final r = _O5mByteReader(data);
    _wayIdDelta += r.readSigned();

    _skipVersionInfoIfPresent(r);

    final refsSectionLen = r.readUnsigned();
    final refsEnd = r.pos + refsSectionLen;

    final refs = <int>[];
    var refId = 0;
    while (r.pos < refsEnd) {
      refId += r.readSigned();
      refs.add(refId);
    }

    final tags = _readTags(r);
    _ways[_wayIdDelta] = OsmWay(id: _wayIdDelta, tags: tags, refs: refs);
  }

  void _parseRelation(List<int> data) {
    final r = _O5mByteReader(data);
    _relIdDelta += r.readSigned();

    _skipVersionInfoIfPresent(r);

    final refsSectionLen = r.readUnsigned();
    final refsEnd = r.pos + refsSectionLen;

    final members = <OsmRelationMember>[];
    var memId = 0;
    while (r.pos < refsEnd) {
      memId += r.readSigned();
      final typeAndRole = _readSingleString(r);
      if (typeAndRole.isEmpty) continue;

      final typeChar = typeAndRole.codeUnitAt(0);
      final role = typeAndRole.length > 1 ? typeAndRole.substring(1) : '';

      final memberType = switch (typeChar) {
        0x30 => MemberType.node,
        0x31 => MemberType.way,
        0x32 => MemberType.relation,
        _ => MemberType.way,
      };

      members.add(OsmRelationMember(memberId: memId, memberType: memberType, role: role));
    }

    final tags = _readTags(r);
    _relations[_relIdDelta] = OsmRelation(id: _relIdDelta, tags: tags, members: members);
  }

  Map<String, String> _readTags(_O5mByteReader r) {
    final tags = <String, String>{};
    while (!r.isEOF) {
      final pair = _readStringPair(r);
      if (pair == null) break;
      tags[pair.key] = pair.value;
    }
    return tags;
  }

  _StringPair? _readStringPair(_O5mByteReader r) {
    if (r.isEOF) return null;

    final first = r.peekByte();
    if (first == 0) {
      r.readByte();
      final key = r.readUtf8UntilZero();
      final value = r.readUtf8UntilZero();
      final pair = _StringPair(key, value);
      _storeStringPair(pair);
      return pair;
    }

    final ref = r.readUnsigned();
    final pair = _resolveStringPairRef(ref);
    return pair;
  }

  String _readSingleString(_O5mByteReader r) {
    if (r.isEOF) return '';

    final first = r.peekByte();
    if (first == 0) {
      r.readByte();
      return r.readUtf8UntilZero();
    }

    final ref = r.readUnsigned();
    final pair = _resolveStringPairRef(ref);
    return pair?.key ?? '';
  }

  void _storeStringPair(_StringPair pair) {
    if ((pair.key.length + pair.value.length) > 250) return;

    _stringTable[_stringTablePos] = pair;
    _stringTablePos = (_stringTablePos + 1) % _stringTableSize;
    if (_stringTableCount < _stringTableSize) _stringTableCount++;
  }

  _StringPair? _resolveStringPairRef(int ref) {
    if (ref <= 0 || ref > _stringTableCount) return null;
    final idx = (_stringTablePos - ref) % _stringTableSize;
    return _stringTable[idx];
  }

  void _skipVersionInfoIfPresent(_O5mByteReader r) {
    if (r.isEOF) return;

    final b = r.peekByte();
    if (b == 0) {
      r.readByte();
      return;
    }

    // version (unsigned)
    r.readUnsigned();

    // timestamp (signed, delta-coded)
    final timestampDelta = r.readSigned();
    if (timestampDelta != 0) {
      // changeset (signed, delta-coded)
      r.readSigned();

      // uid, user (string pair or reference)
      _skipAuthorStringPair(r);
    }
  }

  void _skipAuthorStringPair(_O5mByteReader r) {
    if (r.isEOF) return;

    final first = r.peekByte();
    if (first == 0) {
      r.readByte();
      // first element: uid as unsigned varint bytes until 0x00
      r.skipUntilZero();
      // second element: username utf8 until 0x00
      r.skipUntilZero();
      // not stored in string table to keep logic simple
      return;
    }

    // reference
    r.readUnsigned();
  }

  void _resetDeltas() {
    _idDelta = 0;
    _wayIdDelta = 0;
    _relIdDelta = 0;

    _nodeLonDelta = 0;
    _nodeLatDelta = 0;

    _stringTablePos = 0;
    _stringTableCount = 0;
    for (int i = 0; i < _stringTable.length; i++) {
      _stringTable[i] = null;
    }
  }

  OsmData? _sendData({required bool force}) {
    if (force && _nodes.isEmpty && _ways.isEmpty && _relations.isEmpty) {
      return null;
    }

    if (force || _nodes.length >= 1000000 || _ways.length >= 100000 || _relations.length >= 1000) {
      final osmData = OsmData(
        nodes: _nodes.values.toList(),
        ways: _ways.values.toList(),
        relations: _relations.values.toList(),
      );
      _nodes.clear();
      _ways.clear();
      _relations.clear();
      return osmData;
    }

    return null;
  }

  Future<int> _readUnsigned() async {
    var result = 0;
    var shift = 0;
    while (true) {
      final b = await _raf.readByte();
      if (b == -1) throw StateError('Unexpected EOF');
      final v = b & 0x7F;
      result |= (v << shift);
      if ((b & 0x80) == 0) break;
      shift += 7;
    }
    return result;
  }
}

class _StringPair {
  final String key;
  final String value;

  const _StringPair(this.key, this.value);
}

class _O5mByteReader {
  final List<int> _data;
  int pos = 0;

  _O5mByteReader(this._data);

  bool get isEOF => pos >= _data.length;

  int peekByte() {
    return isEOF ? -1 : _data[pos] & 0xFF;
  }

  int readByte() {
    final b = _data[pos] & 0xFF;
    pos++;
    return b;
  }

  int readUnsigned() {
    var result = 0;
    var shift = 0;
    while (true) {
      final b = readByte();
      final v = b & 0x7F;
      result |= (v << shift);
      if ((b & 0x80) == 0) break;
      shift += 7;
    }
    return result;
  }

  int readSigned() {
    var unsigned = readUnsigned();
    final signBit = unsigned & 1;
    unsigned >>= 1;
    if (signBit == 0) return unsigned;
    return -(unsigned + 1);
  }

  String readUtf8UntilZero() {
    final start = pos;
    while (!isEOF && (_data[pos] != 0)) {
      pos++;
    }
    final bytes = _data.sublist(start, pos);
    if (!isEOF && _data[pos] == 0) pos++;
    return utf8.decode(bytes, allowMalformed: true);
  }

  void skipUntilZero() {
    while (!isEOF && (_data[pos] != 0)) {
      pos++;
    }
    if (!isEOF && _data[pos] == 0) pos++;
  }
}
