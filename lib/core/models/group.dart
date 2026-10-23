// GET /groups 응답의 한 항목
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.maxMembers,
    required this.memberCount,
  });

  // 서버의 id는 BigInt라 JSON에서 문자열로 내려온다.
  final String id;
  final String name;
  final int maxMembers;

  // 목록 API는 멤버 수를 주지 않아서 상세 조회로 따로 채운다.
  final int memberCount;

  factory Group.fromJson(Map<String, dynamic> json) {
    final members = json['group_members'] as List<dynamic>?;
    return Group(
      id: json['id'].toString(),
      name: json['name'] as String,
      maxMembers: json['max_members'] as int? ?? 0,
      memberCount: members?.length ?? 0,
    );
  }
}
