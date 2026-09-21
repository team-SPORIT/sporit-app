import 'package:flutter/material.dart';

import '/core/routes/app_router.dart';
import '/core/services/theme_controller.dart';
import '/shared/app_colors.dart';
import '/shared/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 설정에서 테마를 바꾸면 앱 전체 강조색이 곧바로 따라간다.
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.instance,
      builder: (context, appTheme, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: _themeData(appTheme, Brightness.light),
          darkTheme: _themeData(appTheme, Brightness.dark),
          routerConfig: router,
        );
      },
    );
  }

  ThemeData _themeData(AppTheme appTheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.bg0 : AppColors.bg9,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: appTheme.color,
            brightness: brightness,
          ).copyWith(
            // 브랜드 색을 그대로 써야 해서 fromSeed가 보정한 값을 덮어쓴다.
            primary: appTheme.color,
          ),
    );
  }
}
