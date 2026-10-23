import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../models/group.dart';
import 'auth_service.dart';

class GroupService {
  GroupService._();

  static final GroupService instance = GroupService._();

  // 내가 속한 그룹 목록. 목록 API는 멤버 수를 주지 않아서 그룹마다 상세를
  // 한 번씩 더 불러 멤버 수를 채운다(그룹 수가 많지 않아 병렬로 처리한다).
  Future<List<Group>> fetchMine() async {
    final response = await http.get(
      Uri.parse(Api.groups),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('그룹을 불러오지 못했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    final ids = body
        .map((item) => (item as Map<String, dynamic>)['id'].toString())
        .toList();

    return Future.wait(ids.map(fetchOne));
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

  // 새 그룹 만들기
  Future<void> create(String name, int maxMembers) async {
    final response = await http.post(
      Uri.parse(Api.groups),
      headers: AuthService.instance.authHeaders(json: true),
      body: jsonEncode({'name': name, 'maxMembers': maxMembers}),
    );

    if (response.statusCode >= 400) {
      throw Exception('그룹 만들기에 실패했어요 (${response.statusCode})');
    }
  }
}
