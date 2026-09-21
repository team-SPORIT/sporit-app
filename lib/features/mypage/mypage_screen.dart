import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/profile.dart';
import '../../core/models/user_exercise.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/exercise_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/theme_controller.dart';
import '../../shared/app_colors.dart';
import '../../shared/app_theme.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_input_dialog.dart';
import '../../shared/widgets/app_pill_button.dart';
import '../../shared/widgets/exercise_chip.dart';

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
  bool _isUploadingAvatar = false;

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
    final name = await AppInputDialog.show(
      context,
      title: '선호하는 운동을 추가 해주세요',
      hintText: '배드민턴, 농구',
      confirmText: '추가하기',
      // 서버의 name 컬럼이 VARCHAR(30)이라 입력도 같은 길이로 제한한다.
      maxLength: 30,
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

  Future<void> _handleEditAvatar() async {
    if (_isUploadingAvatar) return;

    // 원본 사진은 5MB를 넘기 쉬워서, 고르는 단계에서 프로필에 필요한 크기로 줄인다.
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final updated = await ProfileService.instance.uploadAvatar(picked.path);
      if (!mounted) return;
      setState(() => _profile = updated);
    } catch (e) {
      _showMessage('$e');
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _handleEditNickname() async {
    final current = _profile?.nickname;
    if (current == null) return;

    final nickname = await AppInputDialog.show(
      context,
      title: '이름을 수정해주세요',
      hintText: '이름을 입력해주세요',
      confirmText: '수정하기',
      initialValue: current,
      // 서버의 nickname 컬럼이 VARCHAR(50)이라 입력도 같은 길이로 제한한다.
      maxLength: 50,
    );
    if (nickname == null || nickname == current) return;

    try {
      final updated = await ProfileService.instance.updateNickname(nickname);
      if (!mounted) return;
      setState(() => _profile = updated);
    } catch (e) {
      _showMessage('$e');
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: '로그아웃 하시겠습니까?',
        actions: [
          AppPillButton(
            label: '로그아웃',
            textColor: AppColors.redWaring,
            borderColor: AppColors.redWaring,
            height: 48,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final borderColor = isDark ? AppColors.bg9 : AppColors.bg0;
    final dividerColor = isDark ? AppColors.bg2 : AppColors.bg7;
    // padding은 키보드가 올라오면 0이 돼버리지만 viewPadding은 그대로라,
    // 홈 인디케이터 높이만큼의 여백을 키보드와 무관하게 유지할 수 있다.
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      // 입력은 다이얼로그에서만 하므로 키보드에 맞춰 본문을 줄일 필요가 없다.
      // 줄이면 화면 아래 고정된 버튼들이 키보드를 따라 올라와버린다.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        // 아래 여백은 아래에서 직접 준다. SafeArea에 맡기면 키보드가 오르내릴 때마다
        // 여백이 사라졌다 돌아오면서 버튼이 내려갔다 올라간다.
        bottom: false,
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
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomSafeInset),
              child: Column(
                children: [
                  AppPillButton(
                    label: '로그아웃',
                    textColor: textColor,
                    borderColor: isDark ? AppColors.bg2 : AppColors.bg6,
                    onPressed: _handleSignOut,
                  ),
                  const SizedBox(height: 12),
                  AppPillButton(
                    label: '회원 탈퇴',
                    textColor: AppColors.redWaring,
                    borderColor: AppColors.redWaring,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Avatar(
                imageUrl: profile?.profileImage,
                isUploading: _isUploadingAvatar,
              ),
              _EditLabel(
                label: '프로필사진 수정하기',
                textColor: textColor,
                onTap: _handleEditAvatar,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _NicknamePill(
                  nickname: profile?.nickname ?? '',
                  textColor: textColor,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 16),
              _EditLabel(
                label: '이름 수정하기',
                textColor: textColor,
                onTap: _handleEditNickname,
              ),
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
                ExerciseChip(
                  label: exercise.name,
                  isDeleting: _deletingIds.contains(exercise.id),
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
  const _Avatar({this.imageUrl, this.isUploading = false});

  final String? imageUrl;
  final bool isUploading;

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
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null)
            Image.network(
              url,
              fit: BoxFit.cover,
              // 이미지를 못 불러오면 기본 회색 원만 보여준다.
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          if (isUploading)
            Container(
              color: AppColors.bg0.withValues(alpha: 0.5),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.bg9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditLabel extends StatelessWidget {
  const _EditLabel({
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: textColor)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 20, color: textColor),
        ],
      ),
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
