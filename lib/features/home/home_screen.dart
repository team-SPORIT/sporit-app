import 'package:flutter/material.dart';

import '../../shared/widgets/app_top_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 상단바 아래 메인 요소(연속 기록 카드, 함께 운동중 목록, 하단 네비게이션) 구현
    return const Scaffold(appBar: AppTopBar(), body: SizedBox.shrink());
  }
}
