import 'package:flutter/material.dart';

import '../../../core/models/group.dart';
import '../../../core/services/theme_controller.dart';
import '../../../shared/app_colors.dart';

// 그룹 한 개를 보여주는 카드. 아래쪽 불꽃 아이콘 하나가 그룹원 한 명이다.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group});

  final Group group;

  // 50명짜리 그룹이어도 카드 밖으로 넘치지 않도록 보여줄 개수를 제한한다.
  // 카드 폭에 5개씩 두 줄이 들어가므로 10개까지만 그리고, 나머지는 +N으로 알린다.
  static const int _maxFlames = 10;

  static const double _flameSize = 18;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;

    final flameCount = group.memberCount.clamp(0, _maxFlames);
    final hiddenCount = group.memberCount - flameCount;

    return Container(
      height: 184,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bg4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const Spacer(),
          // TODO: 그룹 연속 운동 기록 표시 추가
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < flameCount; i++)
                Image.asset(
                  ThemeController.instance.value.iconAsset,
                  width: _flameSize,
                  height: _flameSize,
                ),
              if (hiddenCount > 0)
                Text(
                  '+$hiddenCount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
