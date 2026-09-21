import 'package:flutter/material.dart';

import 'app_colors.dart';

// 백엔드 profiles.theme(enum theme_type)과 1:1로 대응하는 화면 테마.
// 선언 순서가 설정 화면에 보이는 순서다.
enum AppTheme {
  blue(apiValue: 'blue', color: AppColors.main, assetSuffix: 'B'),
  lime(apiValue: 'lime', color: AppColors.theme1, assetSuffix: 'YG'),
  teal(apiValue: 'teal', color: AppColors.theme2, assetSuffix: 'G'),
  pink(apiValue: 'pink', color: AppColors.theme3, assetSuffix: 'PK');

  const AppTheme({
    required this.apiValue,
    required this.color,
    required this.assetSuffix,
  });

  final String apiValue;
  final Color color;

  // 로고/아이콘 에셋 파일명 접미사 (logotype_wh_B.png, icon_B.png ...)
  final String assetSuffix;

  // 저장된 테마를 아직 모를 때(첫 실행, 캐시 없음) 쓰는 기본 테마.
  static const AppTheme fallback = AppTheme.blue;

  static AppTheme fromApiValue(Object? value) {
    return AppTheme.values.firstWhere(
      (theme) => theme.apiValue == value,
      orElse: () => fallback,
    );
  }

  // 로고는 배경(다크/라이트)에 따라 흰색/검정 글자 버전이 따로 있다.
  String logotypeAsset({required bool isDark}) {
    final tone = isDark ? 'wh' : 'bk';
    return 'assets/img/logotype/logotype_${tone}_$assetSuffix.png';
  }

  String get iconAsset => 'assets/img/icon/icon_$assetSuffix.png';
}
