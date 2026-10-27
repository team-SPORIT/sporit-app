import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 진행 중인 운동 한 건. 경과 시간을 숫자로 들고 있지 않고 "언제 시작했는지"와
// "멈춰 있던 총 시간"만 저장해서, 앱을 껐다 켜도 실제 흐른 시간이 그대로 이어진다.
@immutable
class WorkoutSession {
  const WorkoutSession({
    required this.startedAt,
    required this.pausedTotal,
    required this.startPhotoPath,
    required this.photoPaths,
    this.pausedAt,
  });

  final DateTime startedAt;

  // 지금까지 일시정지로 멈춰 있던 시간의 합
  final Duration pausedTotal;

  // 일시정지 중이면 멈춘 시각, 아니면 null
  final DateTime? pausedAt;

  // 운동을 시작하며 찍은 사진. 기록하기 화면에는 보이지 않고 게시할 때 함께 올린다.
  final String startPhotoPath;

  // 운동을 끝내며 찍은 사진. 서버가 한 장만 받으므로 최대 한 장이다.
  final List<String> photoPaths;

  // 파일이 실제로 남아 있는 사진만. 기기 저장공간이 정리돼 사라진 사진은 뺀다.
  List<String> get existingPhotoPaths =>
      photoPaths.where((path) => File(path).existsSync()).toList();

  // 시작 사진이 아직 남아 있으면 그 경로, 지웠거나 사라졌으면 null.
  String? get existingStartPhotoPath =>
      startPhotoPath.isNotEmpty && File(startPhotoPath).existsSync()
      ? startPhotoPath
      : null;

  bool get isPaused => pausedAt != null;

  Duration get elapsed {
    final until = pausedAt ?? DateTime.now();
    return until.difference(startedAt) - pausedTotal;
  }

  WorkoutSession copyWith({
    Duration? pausedTotal,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    String? startPhotoPath,
    List<String>? photoPaths,
  }) {
    return WorkoutSession(
      startedAt: startedAt,
      pausedTotal: pausedTotal ?? this.pausedTotal,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      startPhotoPath: startPhotoPath ?? this.startPhotoPath,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.millisecondsSinceEpoch,
    'pausedTotalMs': pausedTotal.inMilliseconds,
    'pausedAt': pausedAt?.millisecondsSinceEpoch,
    'startPhotoPath': startPhotoPath,
    'photoPaths': photoPaths,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final pausedAt = json['pausedAt'] as int?;
    return WorkoutSession(
      startedAt: DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int),
      pausedTotal: Duration(milliseconds: json['pausedTotalMs'] as int? ?? 0),
      pausedAt: pausedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(pausedAt),
      startPhotoPath: json['startPhotoPath'] as String? ?? '',
      photoPaths: (json['photoPaths'] as List<dynamic>? ?? [])
          .map((path) => path as String)
          .toList(),
    );
  }
}

// 진행 중인 운동을 앱 전체에서 공유하고 기기에도 저장한다.
// 값이 null이면 진행 중인 운동이 없다는 뜻.
class WorkoutSessionController extends ValueNotifier<WorkoutSession?> {
  WorkoutSessionController._() : super(null);

  static final WorkoutSessionController instance = WorkoutSessionController._();

  static const _storageKey = 'workout_session';

  // 앱 시작 시 한 번 호출. 저장된 운동이 있으면 되살린다.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved == null) return;
      super.value = WorkoutSession.fromJson(
        jsonDecode(saved) as Map<String, dynamic>,
      );
    } catch (_) {
      // 저장된 내용이 깨졌으면 없는 것으로 친다.
    }
  }

  @override
  set value(WorkoutSession? newValue) {
    super.value = newValue;
    unawaited(_persist(newValue));
  }

  // 서버가 시작/종료 사진 두 장을 요구하므로 시작 사진도 함께 보관한다.
  // 다만 기록하기 화면에는 끝 사진만 보여준다.
  Future<void> start(String startPhotoPath) async {
    value = WorkoutSession(
      startedAt: DateTime.now(),
      pausedTotal: Duration.zero,
      startPhotoPath: await _keep(startPhotoPath),
      photoPaths: const [],
    );
  }

  void pause() {
    final session = value;
    if (session == null || session.isPaused) return;
    value = session.copyWith(pausedAt: DateTime.now());
  }

  void resume() {
    final session = value;
    final pausedAt = session?.pausedAt;
    if (session == null || pausedAt == null) return;
    value = session.copyWith(
      pausedTotal: session.pausedTotal + DateTime.now().difference(pausedAt),
      clearPausedAt: true,
    );
  }

  // 시작 사진을 다시 찍었을 때도 이전 것을 지우고 덮어쓴다.
  Future<void> setStartPhoto(String path) async {
    if (value == null) return;

    final kept = await _keep(path);
    final session = value;
    if (session == null) return;

    unawaited(_deleteFile(session.startPhotoPath));
    value = session.copyWith(startPhotoPath: kept);
  }

  // 끝 사진은 항상 한 장만 남긴다. 새로 찍으면 이전 사진을 지우고 덮어쓴다.
  // (덧붙이면 끝내기를 여러 번 거칠 때마다 사진이 쌓인다.)
  Future<void> setEndPhoto(String path) async {
    if (value == null) return;

    final kept = await _keep(path);
    final session = value;
    if (session == null) return;

    for (final old in session.photoPaths) {
      unawaited(_deleteFile(old));
    }
    value = session.copyWith(photoPaths: [kept]);
  }

  Future<void> removePhoto(String path) async {
    final session = value;
    if (session == null) return;
    value = session.copyWith(
      startPhotoPath: session.startPhotoPath == path ? '' : null,
      photoPaths: session.photoPaths.where((p) => p != path).toList(),
    );
    // 보관해둔 파일도 함께 지운다.
    await _deleteFile(path);
  }

  Future<void> _deleteFile(String path) async {
    try {
      await File(path).delete();
    } catch (_) {
      // 이미 없으면 그만이다.
    }
  }

  // 카메라가 찍은 사진은 임시 폴더에 생겨서 앱을 껐다 켜면 사라질 수 있다.
  // 운동 기록은 그 사이에도 살아있어야 하므로 앱 전용 폴더로 옮겨둔다.
  Future<String> _keep(String path) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory('${directory.path}/workout_photos');
      await folder.create(recursive: true);
      final name =
          '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
      final copied = await File(path).copy('${folder.path}/$name');
      return copied.path;
    } catch (_) {
      // 복사에 실패하면 원래 경로라도 쓴다.
      return path;
    }
  }

  void finish() {
    // 옮겨둔 사진 파일들도 함께 정리한다.
    final session = value;
    for (final path in [
      if (session != null) session.startPhotoPath,
      ...?session?.photoPaths,
    ]) {
      unawaited(_deleteFile(path));
    }
    value = null;
  }

  Future<void> _persist(WorkoutSession? session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (session == null) {
        await prefs.remove(_storageKey);
      } else {
        await prefs.setString(_storageKey, jsonEncode(session.toJson()));
      }
    } catch (_) {
      // 저장 실패해도 진행 중인 운동은 메모리에 남아 있으므로 무시한다.
    }
  }
}
