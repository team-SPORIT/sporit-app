import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../../shared/app_theme.dart';
import '../models/profile.dart';
import 'auth_service.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  // 내 프로필 조회
  Future<Profile> fetchMe() async {
    final response = await http.get(
      Uri.parse(Api.profilesMe),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('프로필을 불러오지 못했어요 (${response.statusCode})');
    }

    // 한글이 깨지지 않도록 charset 헤더에 의존하지 않고 직접 utf8로 디코딩한다.
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return Profile.fromJson(body as Map<String, dynamic>);
  }

  // 테마 변경 저장 (PATCH는 보낸 필드만 갱신한다)
  Future<void> updateTheme(AppTheme theme) async {
    final response = await http.patch(
      Uri.parse(Api.profilesMe),
      headers: AuthService.instance.authHeaders(json: true),
      body: jsonEncode({'theme': theme.apiValue}),
    );

    if (response.statusCode >= 400) {
      throw Exception('테마 저장에 실패했어요 (${response.statusCode})');
    }
  }
}
