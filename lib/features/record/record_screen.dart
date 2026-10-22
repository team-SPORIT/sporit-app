import 'package:flutter/material.dart';

import '../../shared/app_colors.dart';

// TODO: 운동 기록 저장 화면 구현
// 홈 화면의 PageView 안에서 보여지므로 Scaffold 없이 내용만 그린다.
class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시: 어떤 화면인지만 표시
    return const Center(
      child: Text(
        '기록 저장',
        style: TextStyle(fontSize: 16, color: AppColors.bg4),
      ),
    );
  }
}
