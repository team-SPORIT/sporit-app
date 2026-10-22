import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_pill_button.dart';
import '../../shared/app_colors.dart';
import '../home/home_screen.dart' show homeNavBarHeight, homeNavBarMargin;
import 'widgets/camera_view.dart';

// 홈의 PageView 안에서 보여지는 운동 시작 화면.
// 사진을 찍으면 운동을 시작할지 묻고, 확인하면 타이머 화면으로 넘어간다.
class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key, this.isActive = true});

  // 홈에서 이 페이지가 선택돼 있을 때만 카메라를 연다.
  final bool isActive;

  Future<void> _handleCaptured(BuildContext context, XFile photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: '운동을 시작하겠습니까?',
        actions: [
          AppPillButton(
            label: '취소',
            textColor: Theme.of(dialogContext).brightness == Brightness.dark
                ? AppColors.bg9
                : AppColors.bg1,
            borderColor: AppColors.bg4,
            height: 48,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          AppPillButton(
            label: '시작하기',
            textColor: AppColors.bg9,
            fillColor: Theme.of(dialogContext).colorScheme.primary,
            height: 48,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // 운동 시작 시각은 카운트다운이 끝난 뒤에 잡는다.
    context.push('/record/timer', extra: photo.path);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return CameraView(
      isActive: isActive,
      // 떠 있는 네비게이션이 촬영 버튼을 가리지 않도록 그만큼 자리를 비운다.
      bottomInset: homeNavBarMargin + bottomSafeInset + homeNavBarHeight + 12,
      onCaptured: (photo) => _handleCaptured(context, photo),
    );
  }
}
