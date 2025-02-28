import 'package:mapsforge_flutter/core.dart';

/// Holds data returned from the PbfReader. These data must be converted
/// to PointOfInterest and Way objects before being used.
class PbfData {
  final List<OsmNode> nodes;
  final List<OsmWay> ways;
  final List<OsmRelation> relations;

  PbfData({required this.nodes, required this.ways, required this.relations});

  @override
  String toString() {
    return 'PbfBlockData{nodes: ${nodes.length}, ways: ${ways.length}, relations: ${relations.length}}';
  }
}

//////////////////////////////////////////////////////////////////////////////

sealed class _OsmPrimitive {
  const _OsmPrimitive({required this.id, required this.tags});

  final int id;
  final Map<String, String> tags;
}

//////////////////////////////////////////////////////////////////////////////

/// OSM node
class OsmNode extends _OsmPrimitive implements ILatLong {
  /// OsmNode default constructor
  const OsmNode({
    required super.id,
    required super.tags,
    required this.latitude,
    required this.longitude,
  });

  /// Latitude
  @override
  final double latitude;

  /// Longitude
  @override
  final double longitude;

  @override
  String toString() {
    return 'OsmNode{id: $id, tags: $tags, lat: $latitude, lon: $longitude}';
  }
}

//////////////////////////////////////////////////////////////////////////////

/// OSM way
class OsmWay extends _OsmPrimitive {
  /// OsmWay default constructor
  const OsmWay({required super.id, required super.tags, required this.refs});

  /// List of node references that make up the way
  final List<int> refs;

  @override
  String toString() {
    return 'OsmWay{id: $id, tags: $tags, refs: $refs}';
  }
}

//////////////////////////////////////////////////////////////////////////////

// ignore: public_member_api_docs
enum MemberType { node, way, relation }

enum RoleType {
  unassigned,
  none,
  inner,
  outer,
  subarea,
  label,
  admin_centre,
  start_finish,
  pit_lane,
  apply_to,
  stop,
  platform,
  station,
  house,
  street,
  stop_entry_only,
  platform_entry_only,
  stop_exit_only,
  platform_exit_only,
  member_state,
  to,
  via,
  from,
  number,
  hashtag_number,
  member,
  building,
  garden,
}

//////////////////////////////////////////////////////////////////////////////

class OsmRelationMember {
  /// The id of the member that make up the relation
  final int memberId;

  /// The type of the member
  final MemberType memberType;

  /// The role of the member. Note that not all roles are yet defined in the enum
  final RoleType role;

  const OsmRelationMember({
    required this.memberId,
    required this.memberType,
    required this.role,
  });

  @override
  String toString() {
    return 'OsmRelationMember{member: $memberId, memberType: $memberType, role: $role}';
  }
}

//////////////////////////////////////////////////////////////////////////////

/// OSM relation
class OsmRelation extends _OsmPrimitive {
  /// OsmRelation default constructor
  const OsmRelation({
    required super.id,
    required super.tags,
    required this.members,
  });

  /// List of ids of the members that make up the relation
  /// Should be the same length as [types]
  final List<OsmRelationMember> members;

  @override
  String toString() {
    return 'OsmRelation{id: $id, tags: $tags, members: $members}';
  }
}
