import 'package:flutter/material.dart';

import '../app_colors.dart';

// 앱 공통 다이얼로그 껍데기. 제목 / 내용 / 버튼 구조로, 내용 자리에는 입력칸을
// 넣거나 비워두고, 버튼은 필요한 만큼 actions에 넘긴다(가로로 같은 너비씩 나눈다).
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.actions,
    this.content,
  });

  final String title;
  final List<Widget> actions;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.bg0 : AppColors.bg9,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.bg9 : AppColors.bg1,
              ),
            ),
            // 내용이 없는 확인용 다이얼로그는 제목과 버튼만 남아 허전해지므로
            // 그 경우에 여백을 더 준다.
            if (content == null)
              const SizedBox(height: 82)
            else ...[
              const SizedBox(height: 20),
              content!,
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                for (final (index, action) in actions.indexed) ...[
                  if (index > 0) const SizedBox(width: 12),
                  Expanded(child: action),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
