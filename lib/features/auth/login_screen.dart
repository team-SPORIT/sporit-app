import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';
import '../../shared/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService.instance;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 구글 로그인 후 브라우저 -> 앱 딥링크 복귀 시 signedIn 이벤트가 발생함.
    // 딥링크가 앱이 백그라운드/미실행 상태일 때 처리되어 이미 세션이 있는 채로
    // 이 화면이 열리는 경우엔 signedIn 대신 initialSession으로 전달되므로 함께 처리한다.
    _authSubscription = _authService.authStateChanges.listen((state) async {
      final isSignInEvent =
          state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.initialSession;
      if (!isSignInEvent || state.session == null) return;

      unawaited(_authService.closeOAuthWebView());

      setState(() => _isLoading = true);
      try {
        final isNew = await _authService.syncProfile();
        if (!mounted) return;
        context.go(isNew ? '/info' : '/home');
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 처리 중 오류가 발생했어요: $e')));
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      // 로그인 성공 시 인앱 브라우저를 코드로 직접 닫는데(closeOAuthWebView), 그 여파로
      // iOS에서 여기서 기다리던 launch 호출이 PlatformException으로 완료되는 경우가
      // 있다(실제 로그인 성공 여부는 별도 리스너가 판단하므로 이 예외는 신뢰할 신호가
      // 아니다). 그 경우는 조용히 무시하고, 그 외의 진짜 실패만 에러로 보여준다.
      if (e is PlatformException) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인에 실패했어요: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Expanded(flex: 4, child: SizedBox()),
              Image.asset(
                isDark
                    ? 'assets/img/logotype/logotype_wh_B.png'
                    : 'assets/img/logotype/logotype_bk_B.png',
                width: 170,
              ),
              const SizedBox(height: 36),
              Text(
                '함께 태우는 열정의 불꽃',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.bg8 : AppColors.bg2,
                ),
              ),
              const Expanded(flex: 5, child: SizedBox()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : _GoogleSignInButton(onPressed: _handleGoogleSignIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.bg0 : AppColors.bg9,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: 51,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.bg4),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 16,
                child: Image.asset(
                  'assets/img/google_icon.png',
                  width: 20,
                  height: 20,
                ),
              ),
              Text(
                'Google로 로그인',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.bg6 : AppColors.bg0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
