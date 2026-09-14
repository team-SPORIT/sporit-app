import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../constants/api.dart';
import '../../shared/app_theme.dart';
import '../models/profile.dart';
import 'auth_service.dart';

// 서버가 받아주는 이미지 형식(확장자 -> MIME 서브타입)과 용량 제한.
// 백엔드 profiles.constants.ts와 맞춰둔 값이다.
const _allowedImageTypes = {
  'jpg': 'jpeg',
  'jpeg': 'jpeg',
  'png': 'png',
  'webp': 'webp',
};
const _maxAvatarBytes = 5 * 1024 * 1024;

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

  // 이름 변경. 수정된 프로필을 그대로 돌려준다.
  Future<Profile> updateNickname(String nickname) async {
    final response = await http.patch(
      Uri.parse(Api.profilesMe),
      headers: AuthService.instance.authHeaders(json: true),
      body: jsonEncode({'nickname': nickname}),
    );

    if (response.statusCode >= 400) {
      throw Exception('이름 저장에 실패했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return Profile.fromJson(body as Map<String, dynamic>);
  }

  // 프로필 사진 업로드. 서버가 Storage에 올리고 profile_image까지 갱신해준다.
  Future<Profile> uploadAvatar(String filePath) async {
    final extension = filePath.split('.').last.toLowerCase();
    final subtype = _allowedImageTypes[extension];
    if (subtype == null) {
      throw Exception('jpg, png, webp 이미지만 올릴 수 있어요');
    }

    // 서버도 용량을 막지만, 업로드를 시작하기 전에 걸러서 헛되이 기다리지 않게 한다.
    if (await File(filePath).length() > _maxAvatarBytes) {
      throw Exception('5MB 이하 이미지만 올릴 수 있어요');
    }

    final request = http.MultipartRequest('POST', Uri.parse(Api.profilesAvatar))
      ..headers.addAll(AuthService.instance.authHeaders())
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          // 형식을 명시하지 않으면 octet-stream으로 올라가 서버 검증에 걸린다.
          contentType: MediaType('image', subtype),
        ),
      );

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode >= 400) {
      throw Exception('사진 업로드에 실패했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return Profile.fromJson(body as Map<String, dynamic>);
  }
}
