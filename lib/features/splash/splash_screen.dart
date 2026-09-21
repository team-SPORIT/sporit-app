import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/splash_gate.dart';
import '../../core/services/theme_controller.dart';
import '../../shared/app_theme.dart';

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
    // 스플래시가 떠 있는 동안 로그인 동기화가 끝나 테마가 바뀔 수 있어서
    // 값을 구독해둔다(캐시된 값과 서버 값이 다른 경우).
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.instance,
      builder: (context, appTheme, child) =>
          Scaffold(backgroundColor: appTheme.color, body: child),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 300),
            Image(
              image: AssetImage('assets/img/logotype/logotype_wh.png'),
              width: 170,
            ),
            SizedBox(height: 350),
            Text(
              '함께 태우는 열정의 불꽃',
              style: TextStyle(
                color: Colors.white,
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
