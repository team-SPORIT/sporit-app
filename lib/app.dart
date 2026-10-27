import 'package:flutter/material.dart';

import '/core/routes/app_router.dart';
import '/shared/app_colors.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _themeData(Brightness.light),
      darkTheme: _themeData(Brightness.dark),
      routerConfig: router,
      // 입력칸 바깥 아무 곳이나 누르면 키보드가 내려가도록 앱 전체에 깔아둔다.
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }

  ThemeData _themeData(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.bg0 : AppColors.bg9,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.bg0,
            brightness: brightness,
          ).copyWith(
            // 강조색은 밝은 화면에서는 검정, 어두운 화면에서는 흰색이다.
            primary: isDark ? AppColors.bg9 : AppColors.bg0,
            onPrimary: isDark ? AppColors.bg0 : AppColors.bg9,
          ),
    );
  }
}
