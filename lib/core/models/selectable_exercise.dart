import 'exercise.dart';

// GET /exercises/selectable 응답.
// 내 개인 종목과, 내가 속한 그룹이 허용한 그룹 전용 종목을 함께 내려준다.
class SelectableExercise {
  const SelectableExercise({required this.exercise, required this.isGroupOnly});

  final Exercise exercise;

  // 내 개인 종목이 아니라 그룹에서만 쓸 수 있는 종목이면 true.
  final bool isGroupOnly;

  String get id => exercise.id;
  String get name => exercise.name;

  static List<SelectableExercise> listFromJson(Map<String, dynamic> json) {
    final mine = (json['mine'] as List<dynamic>? ?? [])
        .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
        .toList();

    final items = [
      for (final exercise in mine)
        SelectableExercise(exercise: exercise, isGroupOnly: false),
    ];

    // 같은 이름이 내 종목에도 있으면 그쪽을 쓴다(개인 종목이 우선).
    final seen = {for (final exercise in mine) exercise.name};
    for (final group in json['groups'] as List<dynamic>? ?? []) {
      final exercises =
          (group as Map<String, dynamic>)['exercises'] as List<dynamic>? ?? [];
      for (final item in exercises) {
        final exercise = Exercise.fromJson(item as Map<String, dynamic>);
        if (!seen.add(exercise.name)) continue;
        items.add(SelectableExercise(exercise: exercise, isGroupOnly: true));
      }
    }
    return items;
  }
}
