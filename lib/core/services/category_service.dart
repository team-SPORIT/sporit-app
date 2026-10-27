import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../models/category.dart';
import 'auth_service.dart';

class CategoryService {
  CategoryService._();

  static final CategoryService instance = CategoryService._();

  // 내 선호 운동(카테고리) 목록
  Future<List<ExerciseCategory>> fetchMine() async {
    final body = await _get(Api.categories);
    return (body as List<dynamic>)
        .map((item) => ExerciseCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 고를 수 있는 색 팔레트
  Future<List<PaletteColor>> fetchColors() async {
    final body = await _get(Api.categoryColors);
    return (body as List<dynamic>)
        .map((item) => PaletteColor.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 선호 운동 추가. 같은 이름의 종목도 함께 묶어둔다.
  Future<ExerciseCategory> create({
    required String name,
    required String colorKey,
  }) async {
    final response = await http.post(
      Uri.parse(Api.categories),
      headers: AuthService.instance.authHeaders(json: true),
      body: jsonEncode({
        'name': name,
        'color': colorKey,
        'exerciseNames': [name],
      }),
    );

    if (response.statusCode == 409) {
      throw Exception('이미 있는 이름이에요');
    }
    if (response.statusCode >= 400) {
      throw Exception('추가에 실패했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return ExerciseCategory.fromJson(body as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    final response = await http.delete(
      Uri.parse(Api.categoryById(id)),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('삭제에 실패했어요 (${response.statusCode})');
    }
  }

  Future<dynamic> _get(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('선호 운동을 불러오지 못했어요 (${response.statusCode})');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
