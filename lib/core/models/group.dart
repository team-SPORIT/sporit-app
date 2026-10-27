import 'package:flutter/material.dart';

import 'category.dart';

// GET /groups 응답의 한 항목
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.maxMembers,
    required this.memberCount,
    required this.inviteCode,
    required this.colorHex,
    this.lastSharedAt,
    required this.members,
  });

  // 서버의 id는 BigInt라 JSON에서 문자열로 내려온다.
  final String id;
  final String name;
  final int maxMembers;

  final int memberCount;

  // 다른 사람을 초대할 때 쓰는 8자리 코드
  final String inviteCode;

  // 서버가 팔레트 키와 함께 hex도 내려준다.
  final String? colorHex;

  // 이 그룹에 마지막으로 기록이 올라온 시각. 아직 없으면 null.
  final DateTime? lastSharedAt;

  Color get color => parseHexColor(colorHex);

  // 멤버 목록은 상세 조회(GET /groups/:id)에만 들어 있다.
  // 목록 조회는 인원 수(memberCount)만 준다.
  final List<GroupMember> members;

  factory Group.fromJson(Map<String, dynamic> json) {
    final members = (json['group_members'] as List<dynamic>? ?? const [])
        .map((item) => GroupMember.fromJson(item as Map<String, dynamic>))
        .toList();
    return Group(
      id: json['id'].toString(),
      name: json['name'] as String,
      maxMembers: json['max_members'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? members.length,
      inviteCode: json['invite_code'] as String? ?? '',
      colorHex: json['colorHex'] as String?,
      lastSharedAt: DateTime.tryParse(json['last_shared_at'] as String? ?? ''),
      members: members,
    );
  }
}

class GroupMember {
  const GroupMember({
    required this.id,
    required this.nickname,
    this.profileImage,
  });

  final String id;
  final String nickname;
  final String? profileImage;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? const {};
    return GroupMember(
      id: json['user_id'] as String? ?? '',
      nickname: profile['nickname'] as String? ?? '',
      profileImage: profile['profile_image'] as String?,
    );
  }
}
