import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../constants/api.dart';
import '../models/recent_records.dart';
import 'auth_service.dart';

class RecordService {
  RecordService._();

  static final RecordService instance = RecordService._();

  // 최근 7일 기록. 종목 이름을 주면 그 종목만 받아온다.
  // 월별 조회(/records/me)와 달리 camelCase이고 시작/종료 사진이 모두 들어 있다.
  Future<RecentRecords> fetchRecent({String? exerciseType}) async {
    final uri = Uri.parse(Api.recordsRecent).replace(
      queryParameters: exerciseType == null
          ? null
          : {'exerciseType': exerciseType},
    );

    final response = await http.get(
      uri,
      headers: AuthService.instance.authHeaders(),
    );

    if (response.statusCode >= 400) {
      throw Exception('최근 기록을 불러오지 못했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return RecentRecords.fromJson(body as Map<String, dynamic>);
  }

  // 한 달치 기록을 날짜별로 묶어서 돌려준다 (캘린더용).
  // 키는 일(day), 값은 그날 한 운동 종목 이름들(같은 종목이 여러 번이면 중복).
  Future<Map<int, List<String>>> fetchMonthlyDays(int year, int month) async {
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

    final days = <int, List<String>>{};
    for (final item in body) {
      final record = item as Map<String, dynamic>;
      // record_date는 "2026-08-14T00:00:00.000Z" 형태의 KST 날짜라, 시간대 변환
      // 없이 문자열에서 일자만 읽어야 하루 밀리지 않는다.
      final date = record['record_date'] as String? ?? '';
      if (date.length < 10) continue;
      final day = int.parse(date.substring(8, 10));
      days
          .putIfAbsent(day, () => [])
          .add(record['exercise_type'] as String? ?? '');
    }
    return days;
  }

  // 운동 기록 작성. 서버가 시작/종료 사진 두 장을 모두 요구한다.
  // 만들어진 기록의 id를 돌려준다(그룹에 공유할 때 쓴다).
  Future<String> create({
    required String startPhotoPath,
    required String endPhotoPath,
    required String exerciseId,
    required Duration duration,
    String? comment,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(Api.records))
      ..headers.addAll(AuthService.instance.authHeaders())
      ..fields['exerciseId'] = exerciseId
      ..fields['durationSec'] = '${duration.inSeconds}'
      ..files.add(await _imageFile('startFile', startPhotoPath))
      ..files.add(await _imageFile('endFile', endPhotoPath));

    final trimmedComment = comment?.trim();
    if (trimmedComment != null && trimmedComment.isNotEmpty) {
      request.fields['comment'] = trimmedComment;
    }

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode >= 400) {
      throw Exception('기록 저장에 실패했어요 (${response.statusCode})');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return (body as Map<String, dynamic>)['id'].toString();
  }

  Future<http.MultipartFile> _imageFile(String field, String path) async {
    final extension = path.split('.').last.toLowerCase();
    final subtype = extension == 'png'
        ? 'png'
        : (extension == 'webp' ? 'webp' : 'jpeg');

    return http.MultipartFile.fromPath(
      field,
      path,
      // 형식을 명시하지 않으면 octet-stream으로 올라가 서버 검증에 걸린다.
      contentType: MediaType('image', subtype),
    );
  }
}
