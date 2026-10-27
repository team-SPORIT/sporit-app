import 'package:flutter/material.dart';

import '../../../core/models/group.dart';
import '../../../shared/app_colors.dart';

// 홈의 그룹 목록 카드 한 줄. 그룹마다 지정한 색으로 이름과 불꽃을 칠한다.
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.exerciseNames,
    required this.onTap,
  });

  final Group group;

  // 이 그룹에 올릴 수 있는 종목들. null이면 아직 못 받았고, 비어 있으면 전체 허용.
  final List<String>? exerciseNames;

  final VoidCallback onTap;

  // 50명짜리 그룹이어도 넘치지 않도록 보여줄 개수를 제한한다.
  // 한 줄에 5개씩 두 줄까지만 그리고 나머지는 +N으로 알린다.
  static const int _maxFlames = 10;
  static const double _flameSize = 22;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = group.color;

    final flameCount = group.memberCount.clamp(0, _maxFlames);
    final hiddenCount = group.memberCount - flameCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg1 : AppColors.bg9,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.bg4, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _exerciseLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastSharedLabel(group.lastSharedAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.bg4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: _flameSize * 5 + 6 * 4,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (var i = 0; i < flameCount; i++)
                        // 흰색 아이콘에 그룹 색을 입힌다.
                        Image.asset(
                          'assets/img/icon/icon_wh.png',
                          width: _flameSize,
                          height: _flameSize,
                          color: color,
                        ),
                      if (hiddenCount > 0)
                        Text(
                          '+$hiddenCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${group.memberCount}명 / ${group.maxMembers}명',
                  style: const TextStyle(fontSize: 11, color: AppColors.bg4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 아직 못 받았으면 빈 줄, 전체 허용이면 그렇게, 아니면 종목 이름을 나열한다.
  String _exerciseLabel() {
    final names = exerciseNames;
    if (names == null) return '';
    if (names.isEmpty) return '모든 종목';
    return names.join(', ');
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
