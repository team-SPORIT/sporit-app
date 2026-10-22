import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import 'auth_service.dart';

class RecordService {
  RecordService._();

  static final RecordService instance = RecordService._();

  // 한 달치 기록을 날짜별 개수로 집계해서 돌려준다 (캘린더 농도 표시용).
  // 키는 일(day), 값은 그날의 기록 횟수.
  Future<Map<int, int>> fetchMonthlyCounts(int year, int month) async {
    final uri = Uri.parse(
      Api.recordsMe,
    ).replace(queryParameters: {'year': '$year', 'month': '$month'});

    final response = await http.get(
      uri,
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('기록을 불러오지 못했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

    final counts = <int, int>{};
    for (final item in body) {
      // record_date는 "2026-08-14T00:00:00.000Z" 형태의 KST 날짜라, 시간대 변환
      // 없이 문자열에서 일자만 읽어야 하루 밀리지 않는다.
      final date = (item as Map<String, dynamic>)['record_date'] as String;
      final day = int.parse(date.substring(8, 10));
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }
}
