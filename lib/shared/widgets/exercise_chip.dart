import 'package:flutter/material.dart';

import '../app_colors.dart';

// 선호 운동 한 개를 보여주는 알약 칩.
// 온보딩/마이페이지에서는 지울 수 있는 칩으로, 기록하기에서는 고를 수 있는
// 칩으로 쓴다. 두 모습의 크기와 모양은 완전히 같다.
class ExerciseChip extends StatelessWidget {
  const ExerciseChip({
    super.key,
    required this.label,
    this.onDelete,
    this.isDeleting = false,
    this.isSelected = false,
    this.onTap,
  });

  final String label;

  // null이면 X 없이 글자만 있는 칩이 된다.
  final VoidCallback? onDelete;

  // 서버에서 지워지길 기다리는 중이면 내용 대신 로딩 표시를 보여준다.
  final bool isDeleting;

  // 고르는 용도로 쓸 때, 골라진 칩은 테마색으로 채워진다.
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isSelected
        ? AppColors.bg9
        : (isDark ? AppColors.bg9 : AppColors.bg1);
    const borderColor = AppColors.bg4;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // X가 없으면 오른쪽에도 같은 여백을 줘서 글자가 가운데 오게 한다.
        padding: EdgeInsets.only(
          left: 16,
          right: onDelete == null ? 16 : 10,
          top: 10,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
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
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isDeleting ? null : onDelete,
                      child: Icon(Icons.close, size: 18, color: textColor),
                    ),
                  ],
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
      ),
    );
  }
}
