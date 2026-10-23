import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_exercise.dart';
import '../../core/services/exercise_service.dart';
import '../../core/services/record_service.dart';
import '../../core/services/workout_session.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/app_input_dialog.dart';
import '../../shared/widgets/app_pill_button.dart';
import '../../shared/widgets/exercise_add_button.dart';
import '../../shared/widgets/exercise_chip.dart';
import 'widgets/camera_view.dart';
import 'workout_timer_screen.dart' show formatWorkoutDuration;

// 운동을 마치고 사진 / 시간 / 종목 / 한마디를 정리해 게시하는 화면.
class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key});

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _commentController = TextEditingController();

  List<UserExercise> _exercises = [];
  String? _selectedExercise;
  bool _isSubmitting = false;

  // 꾹 눌러서 삭제 버튼을 띄워둔 사진. 한 번에 한 장만 띄운다.
  String? _deleteTargetPath;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await ExerciseService.instance.fetchMine();
      if (!mounted) return;
      setState(() => _exercises = exercises);
    } catch (_) {
      // 종목을 못 불러와도 + 버튼으로 새로 추가할 수 있으므로 조용히 넘어간다.
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleAddExercise() async {
    final name = await AppInputDialog.show(
      context,
      title: '선호하는 운동을 추가 해주세요',
      hintText: '배드민턴, 농구',
      confirmText: '추가하기',
      // 서버의 name 컬럼이 VARCHAR(30)이라 입력도 같은 길이로 제한한다.
      maxLength: 30,
    );
    if (name == null) return;

    try {
      final added = await ExerciseService.instance.add(name);
      if (!mounted) return;
      setState(() {
        _exercises = [..._exercises, added];
        _selectedExercise = added.name;
      });
    } catch (e) {
      _showMessage('$e');
    }
  }

  Future<void> _handleAddPhoto() async {
    final photo = await Navigator.of(
      context,
    ).push<XFile>(MaterialPageRoute(builder: (_) => const _AddPhotoPage()));
    if (photo == null) return;
    await WorkoutSessionController.instance.addPhoto(photo.path);
    if (mounted) setState(() {});
  }

  Future<void> _handleDeletePhoto(String path) async {
    final session = WorkoutSessionController.instance.value;
    // 서버가 사진 한 장을 반드시 요구하므로 마지막 한 장은 남겨둔다.
    if (session != null && session.existingPhotoPaths.length <= 1) {
      _showMessage('사진은 최소 한 장 필요해요');
      return;
    }

    await WorkoutSessionController.instance.removePhoto(path);
    if (mounted) setState(() => _deleteTargetPath = null);
  }

  Future<void> _handleSubmit() async {
    final session = WorkoutSessionController.instance.value;
    final exerciseType = _selectedExercise;

    if (session == null) return;
    if (exerciseType == null) {
      _showMessage('운동 종목을 골라주세요');
      return;
    }

    final photoPaths = session.existingPhotoPaths;
    if (photoPaths.isEmpty) {
      _showMessage('사진이 없어 기록할 수 없어요');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await RecordService.instance.create(
        // 서버가 사진 한 장만 받으므로 첫 번째(시작 사진)를 올린다.
        photoPath: photoPaths.first,
        exerciseType: exerciseType,
        duration: session.elapsed,
        comment: _commentController.text,
      );
      // 서버에 올라갔으면 화면이 남아 있든 아니든 운동은 끝난 것으로 정리한다.
      // 여기서 지우지 않으면 홈에 돌아갔을 때 타이머가 다시 열린다.
      WorkoutSessionController.instance.finish();
      if (mounted) context.go('/home');
    } catch (e) {
      _showMessage('$e');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final session = WorkoutSessionController.instance.value;
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // 아래에 띄운 게시 버튼이 차지하는 높이(위 여백 12 + 버튼 52 + 아래 여백).
    final buttonAreaHeight = 12 + 52 + 24 + bottomSafeInset;

    if (session == null) return const SizedBox.shrink();

    return Scaffold(
      // 키보드에 맞춰 본문을 줄이면 아래 고정한 게시 버튼이 같이 올라온다.
      // 대신 스크롤 영역 아래에 키보드 높이만큼 여백을 줘서 입력칸은 가려지지 않는다.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        title: const Text('기록하기', style: TextStyle(fontSize: 16)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            // 스크롤 영역의 아래 끝을 키보드 위(키보드가 없으면 게시 버튼 위)에
            // 맞춘다. 안쪽에 여백을 주는 방식과 달리 빈 공간이 생기지 않고,
            // 입력칸을 누르면 줄어든 영역 안에서 자동으로 키보드 위까지 올라온다.
            child: Padding(
              padding: EdgeInsets.only(
                bottom: keyboardInset > 0
                    // 입력칸이 키보드에 딱 붙지 않도록 조금 띄운다.
                    ? keyboardInset + 16
                    : buttonAreaHeight,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PhotoStrip(
                      photoPaths: session.existingPhotoPaths,
                      deleteTargetPath: _deleteTargetPath,
                      onAddPhoto: _handleAddPhoto,
                      onLongPress: (path) =>
                          setState(() => _deleteTargetPath = path),
                      onDismissDelete: () =>
                          setState(() => _deleteTargetPath = null),
                      onDelete: _handleDeletePhoto,
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(label: '시간', textColor: textColor),
                          const SizedBox(height: 8),
                          Text(
                            formatWorkoutDuration(session.elapsed),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _FieldLabel(label: '종목', textColor: textColor),
                          const SizedBox(height: 12),
                          _ExercisePicker(
                            exercises: _exercises,
                            selected: _selectedExercise,
                            // 고른 종목을 다시 누르면 선택이 풀린다.
                            onSelect: (name) => setState(
                              () => _selectedExercise =
                                  _selectedExercise == name ? null : name,
                            ),
                            onAdd: _handleAddExercise,
                          ),
                          const SizedBox(height: 28),
                          _FieldLabel(label: '오늘의 한마디', textColor: textColor),
                          const SizedBox(height: 12),
                          _CommentField(
                            controller: _commentController,
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 게시 버튼은 흐름에서 빼고 화면 아래에 띄운다. Column에 두면 키보드가
          // 올라왔을 때 버튼 자리만 빈 띠로 남는다.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomSafeInset),
              child: AppPillButton(
                label: _isSubmitting ? '게시하는 중...' : '게시하기',
                textColor: AppColors.bg9,
                fillColor: Theme.of(context).colorScheme.primary,
                onPressed: _isSubmitting ? null : _handleSubmit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.photoPaths,
    required this.deleteTargetPath,
    required this.onAddPhoto,
    required this.onLongPress,
    required this.onDismissDelete,
    required this.onDelete,
  });

  final List<String> photoPaths;
  final String? deleteTargetPath;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onLongPress;
  final VoidCallback onDismissDelete;
  final ValueChanged<String> onDelete;

  static const double _size = 260;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: photoPaths.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == photoPaths.length) {
            return _AddPhotoButton(onTap: onAddPhoto);
          }

          final path = photoPaths[index];
          final isDeleteTarget = path == deleteTargetPath;

          return GestureDetector(
            onLongPress: () => onLongPress(path),
            // 삭제 버튼이 떠 있을 때 사진을 다시 누르면 없던 일로 한다.
            onTap: isDeleteTarget ? onDismissDelete : null,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(path),
                    width: _size,
                    height: _size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: _size,
                      height: _size,
                      color: AppColors.bg7,
                    ),
                  ),
                ),
                if (isDeleteTarget) ...[
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: AppColors.bg0.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _DeletePhotoButton(onTap: () => onDelete(path)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeletePhotoButton extends StatelessWidget {
  const _DeletePhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.redWaring,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 20, color: AppColors.bg9),
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _PhotoStrip._size,
        height: _PhotoStrip._size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.bg4),
        ),
        child: const Icon(
          Icons.photo_camera_rounded,
          size: 32,
          color: AppColors.bg4,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.textColor});

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }
}

class _ExercisePicker extends StatelessWidget {
  const _ExercisePicker({
    required this.exercises,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });

  final List<UserExercise> exercises;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final exercise in exercises)
          ExerciseChip(
            label: exercise.name,
            isSelected: exercise.name == selected,
            onTap: () => onSelect(exercise.name),
          ),
        ExerciseAddButton(onTap: onAdd),
      ],
    );
  }
}

class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller, required this.textColor});

  final TextEditingController controller;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: AppColors.bg4, width: 0.5),
    );

    return TextField(
      controller: controller,
      // 서버의 comment 컬럼이 VARCHAR(200)이라 입력도 같은 길이로 제한한다.
      maxLength: 200,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: '오늘의 운동은 어떤 느낌 이었나요?',
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.bg5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: border,
        focusedBorder: border,
        counterText: '',
      ),
    );
  }
}

// 기록하기 화면에서 사진을 더 찍을 때 잠깐 띄우는 카메라.
class _AddPhotoPage extends StatelessWidget {
  const _AddPhotoPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        foregroundColor: AppColors.bg9,
        title: const Text('사진 추가', style: TextStyle(fontSize: 16)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CameraView(
        bottomInset: MediaQuery.viewPaddingOf(context).bottom + 24,
        onCaptured: (photo) async {
          Navigator.of(context).pop(photo);
        },
      ),
    );
  }
}
