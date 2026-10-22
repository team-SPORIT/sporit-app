import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

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

  // 운동 기록 작성. 서버가 사진을 Storage에 올리고 연속 기록까지 갱신한다.
  Future<void> create({
    required String photoPath,
    required String exerciseType,
    required Duration duration,
    String? comment,
  }) async {
    final extension = photoPath.split('.').last.toLowerCase();
    final subtype = extension == 'png'
        ? 'png'
        : (extension == 'webp' ? 'webp' : 'jpeg');

    final request = http.MultipartRequest('POST', Uri.parse(Api.records))
      ..headers.addAll(AuthService.instance.authHeaders())
      ..fields['exerciseType'] = exerciseType
      ..fields['durationMin'] = '${duration.inMinutes}'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          photoPath,
          // 형식을 명시하지 않으면 octet-stream으로 올라가 서버 검증에 걸린다.
          contentType: MediaType('image', subtype),
        ),
      );

    final trimmedComment = comment?.trim();
    if (trimmedComment != null && trimmedComment.isNotEmpty) {
      request.fields['comment'] = trimmedComment;
    }

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode >= 400) {
      throw Exception('기록 저장에 실패했어요 (${response.statusCode})');
    }
  }
}
