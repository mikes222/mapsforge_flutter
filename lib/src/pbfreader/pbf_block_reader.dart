import 'dart:convert';

import 'package:mapsforge_flutter/src/pbfreader/pbf_data.dart';
import 'package:mapsforge_flutter/src/pbfreader/pbf_reader.dart';
import 'package:mapsforge_flutter/src/pbfreader/proto/osmformat.pb.dart';

class PbfBlockReader {
  PbfData readBlock(BlobResult blobResult) {
    final block = PrimitiveBlock.fromBuffer(blobResult.blobOutput);
    final stringTable = block.stringtable.s.map((s) => utf8.decode(s)).toList();
    final latOffset = block.latOffset.toInt();
    final lonOffset = block.lonOffset.toInt();
    final granularity = block.granularity;
    final primitiveGroups = block.primitivegroup;
    final nodes = <OsmNode>[];
    final ways = <OsmWay>[];
    final relations = <OsmRelation>[];
    for (final primitiveGroup in primitiveGroups) {
      if (primitiveGroup.changesets.isNotEmpty) {
        throw Exception('Changesets not supported');
      }
      if (primitiveGroup.nodes.isNotEmpty) {
        throw Exception('Nodes not supported');
      }
      if (primitiveGroup.ways.isNotEmpty) {
        for (final way in primitiveGroup.ways) {
          final id = way.id.toInt();
          var refDelta = 0;
          final refs = way.refs.map((ref) {
            refDelta += ref.toInt();
            return refDelta;
          }).toList();
          final tags = _parseParallelTags(way.keys, way.vals, stringTable);
          ways.add(OsmWay(
            id: id,
            refs: refs,
            tags: tags,
          ));
        }
      }
      if (primitiveGroup.relations.isNotEmpty) {
        for (final relation in primitiveGroup.relations) {
          final id = relation.id.toInt();
          final tags =
              _parseParallelTags(relation.keys, relation.vals, stringTable);
          var refDelta = 0;
          final memberIds = relation.memids.map((ref) {
            refDelta += ref.toInt();
            return refDelta;
          }).toList();
          final types = relation.types.map((type) {
            return switch (type) {
              Relation_MemberType.NODE => MemberType.node,
              Relation_MemberType.WAY => MemberType.way,
              Relation_MemberType.RELATION => MemberType.relation,
              _ => throw Exception('Unknown member type: $type')
            };
          }).toList();
          final roles = relation.rolesSid.map((role) {
            return switch (role) {
              96 => RoleType.number,
              105 => RoleType.none,
              106 => RoleType.admin_centre,
              107 => RoleType.label,
              108 => RoleType.outer,
              109 => RoleType.subarea,
              686 => RoleType.start_finish,
              687 => RoleType.pit_lane,
              758 => RoleType.building,
              790 => RoleType.inner,
              824 => RoleType.number,
              837 => RoleType.apply_to,
              854 => RoleType.to,
              846 => RoleType.from,
              872 => RoleType.stop,
              873 => RoleType.platform,
              874 => RoleType.station,
              1036 => RoleType.number,
              1048 => RoleType.house,
              1049 => RoleType.street,
              1056 => RoleType.number,
              1184 => RoleType.stop_entry_only,
              1185 => RoleType.platform_entry_only,
              1186 => RoleType.stop_exit_only,
              1187 => RoleType.platform_exit_only,
              1214 => RoleType.number,
              1225 => RoleType.number,
              1248 => RoleType.number,
              1423 => RoleType.member_state,
              1448 => RoleType.via,
              >= 1457 && <= 1553 => RoleType.number,
              >= 1575 && <= 1595 => RoleType.number,
              1750 => RoleType.garden,
              >= 1793 && <= 1821 => RoleType.hashtag_number,
              1936 => RoleType.member,
              _ => RoleType.unassigned
              // throw Exception(
              //       'Unknown role type: $role for relation with id $id ${relation.rolesSid}')
            };
          }).toList();

          List<OsmRelationMember> members = [];
          for (int idx = 0; idx < memberIds.length; idx++) {
            int memberId = memberIds[idx];
            MemberType memberType = types[idx];
            RoleType role = roles[idx];
            OsmRelationMember member = OsmRelationMember(
                memberId: memberId, memberType: memberType, role: role);
            members.add(member);
          }
          relations.add(OsmRelation(
            id: id,
            tags: tags,
            members: members,
          ));
        }
      }
      var j = 0;
      if (primitiveGroup.dense.id.isNotEmpty) {
        final dense = primitiveGroup.dense;
        var id = 0;
        var latDelta = 0;
        var lonDelta = 0;
        for (var i = 0; i < dense.id.length; i++) {
          id += dense.id[i].toInt();
          latDelta += dense.lat[i].toInt();
          lonDelta += dense.lon[i].toInt();
          final lat = 1e-9 * (latOffset + granularity * latDelta);
          final lon = (1e-9 * (lonOffset + granularity * lonDelta));
          final tags = <String, String>{};
          final keyVals = dense.keysVals;
          while (dense.keysVals[j] != 0) {
            tags[stringTable[keyVals[j]]] = stringTable[keyVals[j + 1]];
            j += 2;
          }
          j++;
          nodes.add(OsmNode(
            id: id,
            latitude: lat,
            longitude: lon,
            tags: tags,
          ));
        }
      }
    }
    return PbfData(nodes: nodes, ways: ways, relations: relations);
  }

  Map<String, String> _parseParallelTags(
      List<int> keys, List<int> values, List<String> stringTable) {
    final tags = <String, String>{};
    assert(keys.length == values.length);
    for (var i = 0; i < keys.length; i++) {
      if (keys[i] == 0) {
        continue;
      }
      tags[stringTable[keys[i]]] = stringTable[values[i]];
    }
    return tags;
  }
}
