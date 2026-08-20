import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../shared/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _mainColor = AppColors.main;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 로그인 버튼을 누른 직후 돌아온 상황이면 브랜딩 대기 없이 바로 로그인 화면으로
    // 넘긴다. isNew 판별/응답 대기는 로그인 화면의 기존 로딩 스피너가 처리하므로
    // 스플래시는 그 과정에서 다시 보이지 않는다.
    final isReturningFromLogin = await AuthService.consumeOAuthInProgressFlag();
    final delay = isReturningFromLogin
        ? Duration.zero
        : const Duration(seconds: 3);
    Timer(delay, () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _mainColor,
      body: Center(
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
