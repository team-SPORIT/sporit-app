import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../models/weekly_stats.dart';
import 'auth_service.dart';

class StatsService {
  StatsService._();

  static final StatsService instance = StatsService._();

  // 이번 주(월~일) 운동 통계
  Future<WeeklyStats> fetchWeekly() async {
    final response = await http.get(
      Uri.parse(Api.statsWeekly),
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('이번 주 기록을 불러오지 못했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return WeeklyStats.fromJson(body as Map<String, dynamic>);
  }
}
