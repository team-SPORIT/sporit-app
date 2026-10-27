// GET /stats/weekly 응답. 주는 월요일에 시작한다(서버 기준).
class WeeklyStats {
  const WeeklyStats({
    required this.totalSeconds,
    required this.totalCount,
    required this.byExercise,
  });

  final int totalSeconds;
  final int totalCount;

  // 종목별 집계, 운동 시간 내림차순
  final List<WeeklyExerciseStats> byExercise;

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      totalSeconds: json['totalSeconds'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      byExercise: (json['byExercise'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                WeeklyExerciseStats.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class WeeklyExerciseStats {
  const WeeklyExerciseStats({
    required this.exerciseType,
    required this.totalSeconds,
    required this.count,
  });

  final String exerciseType;
  final int totalSeconds;
  final int count;

  factory WeeklyExerciseStats.fromJson(Map<String, dynamic> json) {
    return WeeklyExerciseStats(
      exerciseType: json['exerciseType'] as String? ?? '',
      totalSeconds: json['totalSeconds'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }
}
