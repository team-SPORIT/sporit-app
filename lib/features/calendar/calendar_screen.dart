import 'package:flutter/material.dart';

import '../../shared/app_colors.dart';

// TODO: 캘린더 화면 구현
// 홈 화면의 PageView 안에서 보여지므로 Scaffold 없이 내용만 그린다.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시: 어떤 화면인지만 표시
    return const Center(
      child: Text('캘린더', style: TextStyle(fontSize: 16, color: AppColors.bg4)),
    );
  }
}
