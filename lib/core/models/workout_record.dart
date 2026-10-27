// GET /records/me/recent 의 기록 한 건. 응답이 camelCase이고 사진 두 장이 모두 들어 있다.
class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.exerciseType,
    required this.durationSec,
    required this.recordDate,
    required this.startImageUrl,
    required this.endImageUrl,
    this.comment,
  });

  final String id;
  final String exerciseType;
  final int durationSec;

  // "YYYY-MM-DD" (KST). 시간대 변환 없이 문자열로 들고 있는다.
  final String recordDate;

  final String startImageUrl;
  final String endImageUrl;
  final String? comment;

  DateTime get date => DateTime.parse(recordDate);

  factory WorkoutRecord.fromJson(
    Map<String, dynamic> json, {
    required String exerciseType,
  }) {
    return WorkoutRecord(
      id: json['id'].toString(),
      exerciseType: exerciseType,
      durationSec: json['durationSec'] as int? ?? 0,
      recordDate: (json['recordDate'] as String? ?? '')
          .padRight(10)
          .substring(0, 10),
      startImageUrl: json['startImageUrl'] as String? ?? '',
      endImageUrl: json['endImageUrl'] as String? ?? '',
      comment: json['comment'] as String?,
    );
  }
}
