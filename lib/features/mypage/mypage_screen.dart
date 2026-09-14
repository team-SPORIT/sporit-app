import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/profile.dart';
import '../../core/models/user_exercise.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/exercise_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/theme_controller.dart';
import '../../shared/app_colors.dart';
import '../../shared/app_theme.dart';

// 회원 탈퇴 버튼 전용 강조색 (디자인상 이 화면에서만 쓰인다)
const _withdrawColor = Color(0xffD32F2F);

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  Profile? _profile;
  List<UserExercise> _exercises = [];
  bool _isLoading = true;
  String? _loadError;
  // 삭제 요청이 끝나기 전에 같은 항목을 또 누르는 걸 막는다.
  final Set<String> _deletingIds = {};
  bool _isSavingTheme = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        ProfileService.instance.fetchMe(),
        ExerciseService.instance.fetchMine(),
      ]);
      if (!mounted) return;
      final profile = results[0] as Profile;
      ThemeController.instance.value = profile.theme;
      setState(() {
        _profile = profile;
        _exercises = results[1] as List<UserExercise>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleAddExercise() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddExerciseDialog(),
    );
    if (name == null || name.isEmpty) return;

    try {
      final added = await ExerciseService.instance.add(name);
      if (!mounted) return;
      setState(() => _exercises = [..._exercises, added]);
    } catch (e) {
      _showMessage('$e');
    }
  }

  Future<void> _handleDeleteExercise(UserExercise exercise) async {
    if (_deletingIds.contains(exercise.id)) return;
    setState(() => _deletingIds.add(exercise.id));

    try {
      await ExerciseService.instance.remove(exercise.id);
      if (!mounted) return;
      setState(() {
        _exercises = _exercises.where((e) => e.id != exercise.id).toList();
      });
    } catch (e) {
      _showMessage('$e');
    } finally {
      if (mounted) setState(() => _deletingIds.remove(exercise.id));
    }
  }

  Future<void> _handleSelectTheme(AppTheme theme) async {
    final previous = ThemeController.instance.value;
    if (theme == previous || _isSavingTheme) return;

    // 먼저 화면에 반영해서 색이 바로 바뀌는 걸 보여주고, 저장에 실패하면 되돌린다.
    setState(() => _isSavingTheme = true);
    ThemeController.instance.value = theme;

    try {
      await ProfileService.instance.updateTheme(theme);
    } catch (e) {
      ThemeController.instance.value = previous;
      _showMessage('$e');
    } finally {
      if (mounted) setState(() => _isSavingTheme = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await _confirm(title: '로그아웃 할까요?', confirmText: '로그아웃');
    if (confirmed != true) return;

    await AuthService.instance.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _handleWithdraw() async {
    // TODO: 백엔드에 회원 탈퇴 엔드포인트가 생기면 연결한다.
    _showMessage('회원 탈퇴는 아직 준비 중이에요');
  }

  void _handleBack() {
    // 홈에서 push로 들어오는 게 기본이지만, 곧바로 /mypage로 들어온 경우엔
    // 되돌아갈 화면이 없으므로 홈으로 보낸다.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<bool?> _confirm({required String title, required String confirmText}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소', style: TextStyle(color: AppColors.bg4)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final borderColor = isDark ? AppColors.bg9 : AppColors.bg0;
    final dividerColor = isDark ? AppColors.bg2 : AppColors.bg7;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: textColor),
                    iconSize: 20,
                    onPressed: _handleBack,
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: dividerColor),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                  ? _LoadErrorView(
                      message: _loadError!,
                      textColor: textColor,
                      onRetry: _load,
                    )
                  : _buildContent(textColor, borderColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  _OutlinedActionButton(
                    label: '로그아웃',
                    textColor: textColor,
                    borderColor: isDark ? AppColors.bg2 : AppColors.bg6,
                    onPressed: _handleSignOut,
                  ),
                  const SizedBox(height: 12),
                  _OutlinedActionButton(
                    label: '회원 탈퇴',
                    textColor: _withdrawColor,
                    borderColor: _withdrawColor,
                    onPressed: _handleWithdraw,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor, Color borderColor) {
    final profile = _profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '설정 & 마이 페이지',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: '프로필', textColor: textColor),
          const SizedBox(height: 16),
          Row(
            children: [
              _Avatar(imageUrl: profile?.profileImage),
              const Spacer(),
              // TODO: 프로필 이미지 수정 기능이 정해지면 연결한다.
              _EditLabel(label: '프로필 수정하기', textColor: textColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: _NicknamePill(
                  nickname: profile?.nickname ?? '',
                  textColor: textColor,
                  borderColor: borderColor,
                ),
              ),
              const Spacer(),
              // TODO: 이름 수정 기능이 정해지면 연결한다.
              _EditLabel(label: '이름 수정하기', textColor: textColor),
            ],
          ),
          const SizedBox(height: 32),
          _SectionTitle(title: '테마', textColor: textColor),
          const SizedBox(height: 16),
          ValueListenableBuilder<AppTheme>(
            valueListenable: ThemeController.instance,
            builder: (context, selected, _) => _ThemeSelector(
              selected: selected,
              ringColor: textColor,
              onSelected: _handleSelectTheme,
            ),
          ),
          const SizedBox(height: 32),
          _SectionTitle(title: '선호 운동 관리', textColor: textColor),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final exercise in _exercises)
                _ExerciseChip(
                  label: exercise.name,
                  textColor: textColor,
                  borderColor: borderColor,
                  onDelete: () => _handleDeleteExercise(exercise),
                ),
              _AddExerciseButton(
                borderColor: borderColor,
                iconColor: textColor,
                onTap: _handleAddExercise,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.textColor});

  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.imageUrl});

  final String? imageUrl;

  static const double _size = 70;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(
        color: AppColors.bg4,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? null
          : Image.network(
              url,
              fit: BoxFit.cover,
              // 이미지를 못 불러오면 기본 회색 원만 보여준다.
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
    );
  }
}

class _EditLabel extends StatelessWidget {
  const _EditLabel({required this.label, required this.textColor});

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: textColor)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, size: 20, color: textColor),
      ],
    );
  }
}

class _NicknamePill extends StatelessWidget {
  const _NicknamePill({
    required this.nickname,
    required this.textColor,
    required this.borderColor,
  });

  final String nickname;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Text(
        nickname,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.selected,
    required this.ringColor,
    required this.onSelected,
  });

  final AppTheme selected;
  final Color ringColor;
  final ValueChanged<AppTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final theme in AppTheme.values)
          _ThemeCircle(
            color: theme.color,
            // 선택 표시는 테두리로 하고, 선택되지 않은 것도 투명 테두리를 둬서
            // 원의 자리 크기가 달라지지 않게 한다.
            borderColor: theme == selected ? ringColor : Colors.transparent,
            onTap: () => onSelected(theme),
          ),
      ],
    );
  }
}

class _ThemeCircle extends StatelessWidget {
  const _ThemeCircle({
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  const _ExerciseChip({
    required this.label,
    required this.textColor,
    required this.borderColor,
    required this.onDelete,
  });

  final String label;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 10, top: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 18, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton({
    required this.borderColor,
    required this.iconColor,
    required this.onTap,
  });

  final Color borderColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Icon(Icons.add, size: 18, color: iconColor),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.label,
    required this.textColor,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({
    required this.message,
    required this.textColor,
    required this.onRetry,
  });

  final String message;
  final Color textColor;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

// 선호 운동 이름을 입력받는 다이얼로그. 추가하면 입력한 이름을 반환한다.
class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog();

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('선호 운동 추가', style: TextStyle(fontSize: 16)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        // 서버의 name 컬럼이 VARCHAR(30)이라 입력도 같은 길이로 제한한다.
        maxLength: 30,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: '배드민턴, 농구',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: AppColors.bg4)),
        ),
        TextButton(onPressed: _submit, child: const Text('추가')),
      ],
    );
  }
}
