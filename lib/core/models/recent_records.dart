import 'workout_record.dart';

// GET /records/me/recent 응답. 서버가 정한 기간과 그 안의 기록들.
class RecentRecords {
  const RecentRecords({
    required this.from,
    required this.to,
    required this.records,
  });

  // "YYYY-MM-DD" (KST). 서버가 정한 조회 기간이라 화면 표시도 이걸 따라야 한다.
  final String from;
  final String to;

  final List<WorkoutRecord> records;

  factory RecentRecords.fromJson(Map<String, dynamic> json) {
    final groups = json['exercises'] as List<dynamic>? ?? [];
    return RecentRecords(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      records: [
        for (final group in groups)
          for (final record
              in (group as Map<String, dynamic>)['records'] as List<dynamic>? ??
                  [])
            WorkoutRecord.fromJson(
              record as Map<String, dynamic>,
              exerciseType: group['exerciseType'] as String? ?? '',
            ),
      ],
    );
  }
}
