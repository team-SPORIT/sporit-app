import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/splash_gate.dart';
import '../../shared/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 로그인 팝업에서 막 돌아온 경우를 구분하려고 남겨둔 플래그를 정리한다.
    // (최소 노출 시간은 앱을 켠 시점부터 재므로, 같은 실행 중에 스플래시가 다시
    // 만들어진 이 경우에는 이미 시간이 지나 곧바로 넘어간다.)
    await AuthService.consumeOAuthInProgressFlag();

    await SplashGate.instance.wait();

    // 로그인된 사용자는 AuthService의 전역 리스너가 /home(/info)으로 보낸다.
    if (SplashGate.instance.isNavigationClaimed) return;
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg0 : AppColors.bg9,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 300),
            Image.asset(
              isDark
                  ? 'assets/img/logotype/logotype_wh.png'
                  : 'assets/img/logotype/logotype_bk.png',
              width: 170,
            ),
            const SizedBox(height: 350),
            Text(
              '함께 태우는 열정의 불꽃',
              style: TextStyle(
                color: isDark ? AppColors.bg8 : AppColors.bg2,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
