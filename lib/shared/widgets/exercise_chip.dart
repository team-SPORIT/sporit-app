import 'package:flutter/material.dart';

import '../app_colors.dart';

// 선호 운동 한 개를 보여주는 알약 칩. 온보딩(정보 입력)과 마이페이지가 함께 쓴다.
class ExerciseChip extends StatelessWidget {
  const ExerciseChip({
    super.key,
    required this.label,
    required this.onDelete,
    this.isDeleting = false,
  });

  final String label;
  final VoidCallback onDelete;

  // 서버에서 지워지길 기다리는 중이면 내용 대신 로딩 표시를 보여준다.
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final borderColor = isDark ? AppColors.bg9 : AppColors.bg0;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 10, top: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 삭제 중에는 내용을 감추기만 하고 자리는 그대로 둔다. 아예 빼버리면
          // 칩 크기가 줄면서 옆 칩들이 밀려 움직인다.
          Opacity(
            opacity: isDeleting ? 0 : 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isDeleting ? null : onDelete,
                  child: Icon(Icons.close, size: 18, color: textColor),
                ),
              ],
            ),
          ),
          if (isDeleting)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
        ],
      ),
    );
  }
}
