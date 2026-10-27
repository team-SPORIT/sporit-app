import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/profile.dart';
import '../../core/services/profile_controller.dart';
import '../app_colors.dart';

// 상단바의 + 버튼을 눌렀을 때 고를 수 있는 동작.
enum TopBarAddAction { joinGroup, createGroup }

// 홈 등 메인 화면들이 공통으로 쓰는 상단바. 로고 / 추가 버튼 / 프로필 순으로 배치한다.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.onAddPressed});

  // null이면 + 버튼은 보이기만 하고 눌리지 않는다.
  final ValueChanged<TopBarAddAction>? onAddPressed;

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
              Image.asset(
                isDark
                    ? 'assets/img/logotype/logotype_wh.png'
                    : 'assets/img/logotype/logotype_bk.png',
                width: 116,
              ),
              const Spacer(),
              _AddButton(onSelected: onAddPressed, isDark: isDark),
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
  const _AddButton({required this.onSelected, required this.isDark});

  final ValueChanged<TopBarAddAction>? onSelected;
  final bool isDark;

  static const double _menuWidth = 140;

  // 버튼 바로 아래, 오른쪽 끝을 버튼에 맞춰 메뉴를 띄운다.
  Future<void> _openMenu(BuildContext context) async {
    final button = context.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    const gap = Offset(0, 4);
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          button.size.bottomLeft(Offset.zero) + gap,
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero) + gap,
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final textColor = isDark ? AppColors.bg9 : AppColors.bg0;
    final action = await showMenu<TopBarAddAction>(
      context: context,
      position: position,
      color: isDark ? AppColors.bg0 : AppColors.bg9,
      elevation: 0,
      constraints: const BoxConstraints(
        minWidth: _menuWidth,
        maxWidth: _menuWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.bg4),
      ),
      items: [
        _menuItem(TopBarAddAction.joinGroup, '그룹 참여하기', textColor),
        const PopupMenuDivider(height: 1, color: AppColors.bg3),
        _menuItem(TopBarAddAction.createGroup, '그룹 만들기', textColor),
      ],
    );

    if (action != null) onSelected?.call(action);
  }

  PopupMenuItem<TopBarAddAction> _menuItem(
    TopBarAddAction action,
    String label,
    Color textColor,
  ) {
    return PopupMenuItem(
      value: action,
      height: 42,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = isDark ? AppColors.bg9 : AppColors.bg0;
    final radius = BorderRadius.circular(50);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      // 눌렸을 때 번지는 효과가 알약 모양 밖으로 나가지 않도록 같은 반경을 준다.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: radius,
        onTap: onSelected == null ? null : () => _openMenu(context),
        child: Container(
          width: 56,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.bg4),
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
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onPressed,
      child: ValueListenableBuilder<Profile?>(
        valueListenable: ProfileController.instance,
        builder: (context, profile, _) {
          final imageUrl = profile?.profileImage;

          return Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.bg4,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            // 사진이 없거나 못 불러오면 기본 회색 원만 보여준다.
            child: imageUrl == null
                ? null
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
          );
        },
      ),
    );
  }
}
