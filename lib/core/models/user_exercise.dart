// GET /exercises/me 응답의 한 항목 (선호 운동)
class UserExercise {
  const UserExercise({required this.id, required this.name});

  // 서버의 id는 BigInt라 JSON에서 문자열로 내려온다.
  final String id;
  final String name;

  factory UserExercise.fromJson(Map<String, dynamic> json) {
    return UserExercise(
      id: json['id'].toString(),
      name: json['name'] as String,
    );
  }
}
