import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/group.dart';
import '../../core/models/selectable_exercise.dart';
import '../../core/services/exercise_service.dart';
import '../../core/services/group_service.dart';
import '../../core/services/profile_controller.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/record_service.dart';
import '../../core/utils/duration_format.dart';
import '../../core/services/workout_session.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/app_input_dialog.dart';
import '../../shared/widgets/app_pill_button.dart';
import '../../shared/widgets/exercise_add_button.dart';
import '../../shared/widgets/exercise_chip.dart';
import '../home/home_screen.dart' show HomeTab;
import 'widgets/camera_view.dart';

// 운동을 마치고 사진 / 시간 / 종목 / 한마디를 정리해 게시하는 화면.
class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key});

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _commentController = TextEditingController();

  List<SelectableExercise> _exercises = [];
  SelectableExercise? _selectedExercise;

  // 고른 종목으로 올릴 수 있는 그룹들과, 그중 실제로 올릴 그룹
  List<Group> _groups = [];
  final Set<String> _selectedGroupIds = {};
  bool _isLoadingGroups = false;
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
      final exercises = await ExerciseService.instance.fetchSelectable();
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

  // 고른 종목을 다시 누르면 선택이 풀린다.
  Future<void> _handleSelectExercise(SelectableExercise exercise) async {
    final isSame = _selectedExercise?.id == exercise.id;
    setState(() {
      _selectedExercise = isSame ? null : exercise;
      _groups = [];
      _selectedGroupIds.clear();
      _isLoadingGroups = !isSame;
    });
    if (isSame) return;

    try {
      final groups = await ExerciseService.instance.fetchGroupsFor(exercise.id);
      if (!mounted || _selectedExercise?.id != exercise.id) return;
      setState(() {
        _groups = groups;
        // 올릴 수 있는 그룹은 기본으로 모두 켜둔다.
        _selectedGroupIds.addAll(groups.map((group) => group.id));
        _isLoadingGroups = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
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
        final selectable = SelectableExercise(
          exercise: added,
          isGroupOnly: false,
        );
        _exercises = [..._exercises, selectable];
        _selectedExercise = selectable;
      });
    } catch (e) {
      _showMessage('$e');
    }
  }

  Future<void> _handleTakePhoto({required bool isStart}) async {
    final photo = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (_) => _TakePhotoPage(title: isStart ? '시작 사진' : '끝 사진'),
      ),
    );
    if (photo == null) return;

    final controller = WorkoutSessionController.instance;
    if (isStart) {
      await controller.setStartPhoto(photo.path);
    } else {
      await controller.setEndPhoto(photo.path);
    }
    if (mounted) setState(() {});
  }

  Future<void> _handleDeletePhoto(String path) async {
    await WorkoutSessionController.instance.removePhoto(path);
    if (mounted) setState(() => _deleteTargetPath = null);
  }

  // 공유에 실패해도 기록 자체는 저장됐으므로 흐름을 멈추지 않는다.
  Future<void> _shareToSelectedGroups(String recordId) async {
    for (final groupId in _selectedGroupIds) {
      try {
        await GroupService.instance.share(recordId: recordId, groupId: groupId);
      } catch (_) {
        // 한 그룹이 실패해도 나머지는 올린다.
      }
    }
  }

  // 실패해도 기록 자체는 저장됐으므로 흐름을 멈추지 않는다.
  Future<void> _refreshProfile() async {
    try {
      ProfileController.instance.value = await ProfileService.instance
          .fetchMe();
    } catch (_) {
      // 다음에 프로필을 받아올 때 맞춰진다.
    }
  }

  Future<void> _handleSubmit() async {
    final session = WorkoutSessionController.instance.value;
    final exercise = _selectedExercise;

    if (session == null) return;
    if (exercise == null) {
      _showMessage('운동 종목을 골라주세요');
      return;
    }

    // 서버가 시작/끝 두 장을 모두 요구한다.
    final startPhotoPath = session.existingStartPhotoPath;
    final endPhotoPath = session.existingPhotoPaths.firstOrNull;
    if (startPhotoPath == null) {
      _showMessage('시작 사진을 다시 찍어주세요');
      return;
    }
    if (endPhotoPath == null) {
      _showMessage('끝 사진을 찍어주세요');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final recordId = await RecordService.instance.create(
        startPhotoPath: startPhotoPath,
        endPhotoPath: endPhotoPath,
        exerciseId: exercise.id,
        duration: session.elapsed,
        comment: _commentController.text,
      );

      // TODO: 그룹 선택 화면이 생기면 고른 그룹에만 공유한다.
      // 지금은 내가 속한 모든 그룹에 올려야 그룹 피드가 열린다.
      await _shareToSelectedGroups(recordId);

      // 서버가 연속 기록을 갱신했으므로 프로필을 다시 받아둔다.
      // 이게 있어야 홈의 연속 기록 카드가 곧바로 바뀐다.
      await _refreshProfile();

      // 서버에 올라갔으면 화면이 남아 있든 아니든 운동은 끝난 것으로 정리한다.
      // 여기서 지우지 않으면 홈에 돌아갔을 때 타이머가 다시 열린다.
      WorkoutSessionController.instance.finish();
      // 운동을 기록 탭(카메라)에서 시작했더라도 끝나면 홈 탭으로 돌아간다.
      if (mounted) context.go('/home', extra: HomeTab.home);
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
                      startPhotoPath: session.existingStartPhotoPath,
                      endPhotoPath: session.existingPhotoPaths.firstOrNull,
                      deleteTargetPath: _deleteTargetPath,
                      onTakeStart: () => _handleTakePhoto(isStart: true),
                      onTakeEnd: () => _handleTakePhoto(isStart: false),
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
                            formatSeconds(session.elapsed.inSeconds),
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
                            onSelect: _handleSelectExercise,
                            onAdd: _handleAddExercise,
                          ),
                          const SizedBox(height: 28),
                          if (_selectedExercise != null) ...[
                            const SizedBox(height: 20),
                            _GroupPicker(
                              exerciseName: _selectedExercise!.name,
                              groups: _groups,
                              selectedIds: _selectedGroupIds,
                              isLoading: _isLoadingGroups,
                              textColor: textColor,
                              onToggle: (groupId) => setState(() {
                                if (!_selectedGroupIds.remove(groupId)) {
                                  _selectedGroupIds.add(groupId);
                                }
                              }),
                            ),
                            const SizedBox(height: 28),
                          ],
                          _FieldLabel(label: '오늘의 한마디', textColor: textColor),
                          const SizedBox(height: 12),
                          _CommentField(
                            controller: _commentController,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 50),
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
                textColor: Theme.of(context).colorScheme.onPrimary,
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
    required this.startPhotoPath,
    required this.endPhotoPath,
    required this.deleteTargetPath,
    required this.onTakeStart,
    required this.onTakeEnd,
    required this.onLongPress,
    required this.onDismissDelete,
    required this.onDelete,
  });

  // 파일이 없으면 null. 그 자리에는 다시 찍을 수 있는 버튼이 뜬다.
  final String? startPhotoPath;
  final String? endPhotoPath;

  final String? deleteTargetPath;
  final VoidCallback onTakeStart;
  final VoidCallback onTakeEnd;
  final ValueChanged<String> onLongPress;
  final VoidCallback onDismissDelete;
  final ValueChanged<String> onDelete;

  static const double _size = 220;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _size,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _PhotoSlot(
            label: '시작',
            path: startPhotoPath,
            isDeleteTarget:
                startPhotoPath != null && startPhotoPath == deleteTargetPath,
            onTake: onTakeStart,
            onLongPress: onLongPress,
            onDismissDelete: onDismissDelete,
            onDelete: onDelete,
          ),
          const SizedBox(width: 12),
          _PhotoSlot(
            label: '끝',
            path: endPhotoPath,
            isDeleteTarget:
                endPhotoPath != null && endPhotoPath == deleteTargetPath,
            onTake: onTakeEnd,
            onLongPress: onLongPress,
            onDismissDelete: onDismissDelete,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

// 사진 한 자리. 사진이 있으면 보여주고, 없으면 찍을 수 있는 버튼이 된다.
class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.label,
    required this.path,
    required this.isDeleteTarget,
    required this.onTake,
    required this.onLongPress,
    required this.onDismissDelete,
    required this.onDelete,
  });

  final String label;
  final String? path;
  final bool isDeleteTarget;
  final VoidCallback onTake;
  final ValueChanged<String> onLongPress;
  final VoidCallback onDismissDelete;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final photoPath = path;

    return SizedBox(
      width: _PhotoStrip._size,
      // 삭제 버튼이 떠 있을 때 사진을 덮는 반투명 막이 탭을 가로채므로,
      // 탭 처리는 Stack 바깥에서 받아야 아무 데나 눌러도 취소된다.
      child: GestureDetector(
        onLongPress: photoPath == null ? null : () => onLongPress(photoPath),
        onTap: isDeleteTarget ? onDismissDelete : null,
        child: Stack(
          children: [
            if (photoPath == null)
              _TakePhotoButton(onTap: onTake)
            else
              ClipRRect(
                borderRadius: radius,
                child: Image.file(
                  File(photoPath),
                  width: _PhotoStrip._size,
                  height: _PhotoStrip._size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _TakePhotoButton(onTap: onTake),
                ),
              ),
            if (isDeleteTarget && photoPath != null) ...[
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: radius,
                  child: Container(
                    color: AppColors.bg0.withValues(alpha: 0.45),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _DeletePhotoButton(onTap: () => onDelete(photoPath)),
              ),
            ],
            // 어느 쪽이 시작이고 끝인지 사진 위에 표시한다.
            Positioned(top: 8, left: 8, child: _PhotoLabel(label: label)),
          ],
        ),
      ),
    );
  }
}

class _PhotoLabel extends StatelessWidget {
  const _PhotoLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg0.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.bg9,
        ),
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

class _TakePhotoButton extends StatelessWidget {
  const _TakePhotoButton({required this.onTap});

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

  final List<SelectableExercise> exercises;
  final SelectableExercise? selected;
  final ValueChanged<SelectableExercise> onSelect;
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
            // 그룹에서만 쓸 수 있는 종목이라는 걸 작게 알려준다.
            badge: exercise.isGroupOnly ? '그룹종목' : null,
            isSelected: exercise.id == selected?.id,
            onTap: () => onSelect(exercise),
          ),
        ExerciseAddButton(onTap: onAdd),
      ],
    );
  }
}

// 고른 종목을 올릴 수 있는 그룹 목록. 켜둔 그룹에만 기록이 올라간다.
class _GroupPicker extends StatelessWidget {
  const _GroupPicker({
    required this.exerciseName,
    required this.groups,
    required this.selectedIds,
    required this.isLoading,
    required this.textColor,
    required this.onToggle,
  });

  final String exerciseName;
  final List<Group> groups;
  final Set<String> selectedIds;
  final bool isLoading;
  final Color textColor;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$exerciseName을 하는 그룹',
          style: const TextStyle(fontSize: 13, color: AppColors.bg4),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (groups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '이 종목을 올릴 수 있는 그룹이 없어요',
              style: TextStyle(fontSize: 13, color: AppColors.bg4),
            ),
          )
        else
          for (final group in groups) ...[
            if (group != groups.first) const SizedBox(height: 8),
            _GroupRow(
              group: group,
              exerciseName: exerciseName,
              isSelected: selectedIds.contains(group.id),
              textColor: textColor,
              onTap: () => onToggle(group.id),
            ),
          ],
      ],
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.exerciseName,
    required this.isSelected,
    required this.textColor,
    required this.onTap,
  });

  final Group group;
  final String exerciseName;
  final bool isSelected;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.bg4, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? group.color : AppColors.bg6,
              ),
              child: Icon(
                Icons.check,
                size: 22,
                color: isSelected ? AppColors.bg9 : AppColors.bg4,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: group.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exerciseName,
                    style: TextStyle(fontSize: 13, color: group.color),
                  ),
                ],
              ),
            ),
            Text(
              _lastSharedLabel(group.lastSharedAt),
              style: const TextStyle(fontSize: 11, color: AppColors.bg4),
            ),
          ],
        ),
      ),
    );
  }

  String _lastSharedLabel(DateTime? at) {
    if (at == null) return '아직 기록 없음';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return '방금 업로드';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전에 업로드';
    if (diff.inDays < 1) return '${diff.inHours}시간 전에 업로드';
    return '${diff.inDays}일 전에 업로드';
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

// 기록하기 화면에서 사진을 다시 찍을 때 잠깐 띄우는 카메라.
class _TakePhotoPage extends StatelessWidget {
  const _TakePhotoPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title, style: const TextStyle(fontSize: 16)),
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
