// GET /exercises 응답의 한 항목 (개인 종목)
class Exercise {
  const Exercise({required this.id, required this.name});

  // 서버의 id는 BigInt라 JSON에서 문자열로 내려온다.
  final String id;
  final String name;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(id: json['id'].toString(), name: json['name'] as String);
  }
}
