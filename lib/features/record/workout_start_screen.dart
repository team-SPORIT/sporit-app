import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_colors.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_pill_button.dart';
import 'widgets/camera_view.dart';

// 그룹에서 바로 운동을 시작할 때 쓰는 전체 화면 카메라.
// 홈의 기록 탭과 달리 하단 네비게이션이 없다.
class WorkoutStartScreen extends StatelessWidget {
  const WorkoutStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        titleSpacing: 0,
        title: const Text('운동 시작하기', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: CameraView(
        bottomInset: MediaQuery.viewPaddingOf(context).bottom + 24,
        onCaptured: (photo) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AppDialog(
              title: '운동을 시작하겠습니까?',
              actions: [
                AppPillButton(
                  label: '취소',
                  textColor: textColor,
                  borderColor: AppColors.bg4,
                  height: 48,
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
                AppPillButton(
                  label: '시작하기',
                  textColor: Theme.of(dialogContext).colorScheme.onPrimary,
                  fillColor: Theme.of(dialogContext).colorScheme.primary,
                  height: 48,
                  onPressed: () => Navigator.pop(dialogContext, true),
                ),
              ],
            ),
          );
          if (confirmed != true || !context.mounted) return;
          context.pushReplacement('/record/timer', extra: photo.path);
        },
      ),
    );
  }
}
