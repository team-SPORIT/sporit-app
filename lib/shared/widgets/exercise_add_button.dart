import 'package:flutter/material.dart';

import '../app_colors.dart';

// 선호 운동을 추가하는 + 버튼. 칩들 옆에 같은 모양으로 선다.
class ExerciseAddButton extends StatelessWidget {
  const ExerciseAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.bg4, width: 0.5),
        ),
        child: Icon(
          Icons.add,
          size: 18,
          color: isDark ? AppColors.bg9 : AppColors.bg1,
        ),
      ),
    );
  }
}
