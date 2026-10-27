import 'package:flutter/material.dart';

import '../../../core/models/weekly_stats.dart';
import '../../../core/utils/duration_format.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/fire_level.dart';

// 홈 맨 위의 불꽃과 이번 주 총 운동 시간.
class WeeklySummary extends StatelessWidget {
  const WeeklySummary({super.key, required this.stats});

  final WeeklyStats? stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;

    return Column(
      children: [
        // TODO: 불꽃에 애니메이션 적용
        // 흰색 아이콘에 이번 주 운동량에 따른 불꽃 색을 입힌다.
        Image.asset(
          'assets/img/icon/icon_wh.png',
          width: 96,
          color: fireColorForSeconds(stats?.totalSeconds ?? 0),
        ),
        const SizedBox(height: 8),
        Text(
          formatSeconds(stats?.totalSeconds ?? 0),
          style: TextStyle(
            fontFamily: 'Infinite',
            fontSize: 44,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// "이번 주 기록"의 종목별 카드 한 장.
class WeeklyExerciseCard extends StatelessWidget {
  const WeeklyExerciseCard({
    super.key,
    required this.stats,
    required this.color,
    required this.onTap,
  });

  final WeeklyExerciseStats stats;
  final Color color;
  final VoidCallback onTap;

  static const double width = 170;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg1 : AppColors.bg9,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.bg4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stats.exerciseType,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatSeconds(stats.totalSeconds),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${stats.count}회',
              style: const TextStyle(fontSize: 12, color: AppColors.bg4),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              // 흰색 아이콘에 종목 색을 입힌다.
              child: Image.asset(
                'assets/img/icon/icon_wh.png',
                width: 26,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
