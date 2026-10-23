import 'package:flutter/material.dart';

import '../../../core/models/profile.dart';
import '../../../shared/app_colors.dart';

// 며칠 연속으로 운동했는지 보여주는 카드.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final streak = profile?.effectiveStreak ?? 0;
    final hasRecordedToday = profile?.hasRecordedToday ?? false;

    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasRecordedToday ? '오늘의 운동을\n완료했어요' : '오늘의 운동을\n시작해요',
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.bg9,
                  ),
                ),
                const Spacer(),
                Text(
                  streak > 0
                      ? '$streak일 동안 연속운동\n기록을 유지하고 있어요'
                      : '오늘부터 연속운동\n기록을 시작해보세요',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.bg9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streak',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.bg9,
                ),
              ),
              const SizedBox(width: 8),
              Image.asset('assets/img/icon/icon_wh.png', width: 48),
            ],
          ),
        ],
      ),
    );
  }
}
