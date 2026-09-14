import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../models/user_exercise.dart';
import 'auth_service.dart';

class ExerciseService {
  ExerciseService._();

  static final ExerciseService instance = ExerciseService._();

  // 내 선호 운동 목록 조회 (등록 순)
  Future<List<UserExercise>> fetchMine() async {
    final response = await http.get(
      Uri.parse(Api.exercisesMe),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('선호 운동을 불러오지 못했어요 (${response.statusCode})');
    }

    // 한글이 깨지지 않도록 charset 헤더에 의존하지 않고 직접 utf8로 디코딩한다.
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return body
        .map((item) => UserExercise.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 선호 운동 추가
  Future<UserExercise> add(String name) async {
    final response = await http.post(
      Uri.parse(Api.exercises),
      headers: AuthService.instance.authHeaders(json: true),
      body: jsonEncode({'name': name}),
    );

    // 409는 서버의 @@unique(user_id, name) 위반, 즉 이미 등록해둔 종목이라는 뜻
    if (response.statusCode == 409) {
      throw Exception('이미 등록된 운동이에요');
    }
    if (response.statusCode >= 400) {
      throw Exception('선호 운동 추가에 실패했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return UserExercise.fromJson(body as Map<String, dynamic>);
  }

  // 선호 운동 삭제
  Future<void> remove(String id) async {
    final response = await http.delete(
      Uri.parse(Api.exerciseById(id)),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('선호 운동 삭제에 실패했어요 (${response.statusCode})');
    }
  }
}
