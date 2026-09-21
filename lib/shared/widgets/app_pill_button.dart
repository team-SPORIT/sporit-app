import 'package:flutter/material.dart';

// 앱 전체에서 쓰는 알약 모양 버튼.
// fillColor를 주면 채워진 버튼, borderColor를 주면 테두리 버튼이 된다.
class AppPillButton extends StatelessWidget {
  const AppPillButton({
    super.key,
    required this.label,
    required this.textColor,
    required this.onPressed,
    this.fillColor,
    this.borderColor,
    this.height = 52,
  });

  final String label;
  final Color textColor;

  // null이면 눌리지 않는 상태가 된다.
  final VoidCallback? onPressed;

  final Color? fillColor;
  final Color? borderColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(50);

    return Material(
      color: fillColor ?? Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
