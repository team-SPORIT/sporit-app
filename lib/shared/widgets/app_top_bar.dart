import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/theme_controller.dart';
import '../app_colors.dart';
import '../app_theme.dart';

// 홈 등 메인 화면들이 공통으로 쓰는 상단바. 로고 / 추가 버튼 / 프로필 순으로 배치한다.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.onAddPressed});

  // TODO: 추가 기능이 정해지면 연결한다. null이면 버튼은 보이기만 하고 동작하지 않는다.
  final VoidCallback? onAddPressed;

  static const double _height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Scaffold의 appBar 자리에 들어가는 위젯은 상태바 영역을 직접 피해줘야 한다.
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: _height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              ValueListenableBuilder<AppTheme>(
                valueListenable: ThemeController.instance,
                builder: (context, appTheme, _) => Image.asset(
                  appTheme.logotypeAsset(isDark: isDark),
                  width: 116,
                ),
              ),
              const Spacer(),
              _AddButton(onPressed: onAddPressed, isDark: isDark),
              const SizedBox(width: 12),
              _ProfileButton(onPressed: () => context.push('/mypage')),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed, required this.isDark});

  final VoidCallback? onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lineColor = isDark ? AppColors.bg9 : AppColors.bg0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: lineColor),
          ),
          child: Icon(Icons.add, size: 20, color: lineColor),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // TODO: 프로필 이미지가 준비되면 회색 원 대신 사용자 이미지를 보여준다.
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.bg4,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
