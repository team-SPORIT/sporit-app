import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../models/group.dart';
import '../models/group_feed.dart';
import 'auth_service.dart';

class GroupService {
  GroupService._();

  static final GroupService instance = GroupService._();

  // 내가 속한 그룹 목록. 인원 수까지 한 번에 내려온다.
  Future<List<Group>> fetchMine() async {
    final response = await http.get(
      Uri.parse(Api.groups),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('그룹을 불러오지 못했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return body
        .map((item) => Group.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Group> fetchOne(String id) async {
    final response = await http.get(
      Uri.parse(Api.groupById(id)),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('그룹을 불러오지 못했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return Group.fromJson(body as Map<String, dynamic>);
  }

  // 초대 코드로 참여
  Future<void> join(String code) async {
    final response = await http.post(
      Uri.parse(Api.groupsJoin),
      headers: AuthService.instance.authHeaders(json: true),
      body: jsonEncode({'code': code}),
    );

    // 서버가 상황별로 다른 상태 코드를 주므로 그대로 안내한다.
    if (response.statusCode == 404) {
      throw Exception('없는 초대 코드예요');
    }
    if (response.statusCode == 409) {
      throw Exception('이미 참여한 그룹이에요');
    }
    if (response.statusCode == 400) {
      throw Exception('그룹 정원이 가득 찼어요');
    }
    if (response.statusCode >= 400) {
      throw Exception('그룹 참여에 실패했어요 (${response.statusCode})');
    }
  }

  // 새 그룹 만들기. 만들어진 그룹 id를 돌려준다.
  Future<String> create({
    required String name,
    required int maxMembers,
    required String colorKey,
    required List<String> exerciseNames,
  }) async {
    final response = await http.post(
      Uri.parse(Api.groups),
      headers: AuthService.instance.authHeaders(json: true),
      body: jsonEncode({
        'name': name,
        'maxMembers': maxMembers,
        'color': colorKey,
        // 종목을 고르지 않으면 모든 종목을 허용한다.
        'allowAll': exerciseNames.isEmpty,
        if (exerciseNames.isNotEmpty) 'names': exerciseNames,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('그룹 만들기에 실패했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return (body as Map<String, dynamic>)['id'].toString();
  }

  // 그룹 피드. 내가 오늘 공유하지 않았으면 locked로 내려온다.
  Future<GroupFeed> fetchFeed(String groupId) async {
    final response = await http.get(
      Uri.parse(Api.groupFeed(groupId)),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('그룹 피드를 불러오지 못했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return GroupFeed.fromJson(body as Map<String, dynamic>);
  }

  // 기록을 그룹에 공유
  Future<void> share({
    required String recordId,
    required String groupId,
  }) async {
    final response = await http.post(
      Uri.parse(Api.shares),
      headers: AuthService.instance.authHeaders(json: true),
      body: jsonEncode({'recordId': recordId, 'groupId': groupId}),
    );

    if (response.statusCode >= 400) {
      throw Exception('그룹 공유에 실패했어요 (${response.statusCode})');
    }
  }

  // 그룹에 올릴 수 있는 종목 설정. allowAll이 false면 names에 적은 종목만 허용된다.
  Future<void> setExercises({
    required String groupId,
    required bool allowAll,
    required List<String> names,
  }) async {
    final response = await http.put(
      Uri.parse(Api.groupExercises(groupId)),
      headers: AuthService.instance.authHeaders(json: true),
      body: jsonEncode({'allowAll': allowAll, 'names': names}),
    );

    if (response.statusCode >= 400) {
      throw Exception('허용 종목 설정에 실패했어요 (${response.statusCode})');
    }
  }

  // 그룹에 올릴 수 있는 종목. allowAll이면 모든 종목을 허용한다는 뜻이다.
  Future<({bool allowAll, List<String> names})> fetchExercises(
    String groupId,
  ) async {
    final response = await http.get(
      Uri.parse(Api.groupExercises(groupId)),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('허용 종목을 불러오지 못했어요 (${response.statusCode})');
    }

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (
      allowAll: body['allowAll'] as bool? ?? true,
      names: (body['exercises'] as List<dynamic>? ?? [])
          .map((item) => (item as Map<String, dynamic>)['name'] as String)
          .toList(),
    );
  }
}
