import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../../core/services/auth_service.dart';
import '../../shared/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 로그인 감지 -> 동기화 -> 화면 이동은 AuthService.startSignInListener()가
    // 앱 전체에서 한 번만 처리한다(이 화면이 중간에 다시 만들어져도 안전하도록).
    // 여기서는 그 진행 상태만 관찰해서 스피너/에러 메시지를 보여준다.
    _isLoading = _authService.isSyncingNotifier.value;
    _authService.isSyncingNotifier.addListener(_handleSyncingChanged);
    _authService.syncErrorNotifier.addListener(_handleSyncError);
  }

  void _handleSyncingChanged() {
    if (!mounted) return;
    setState(() => _isLoading = _authService.isSyncingNotifier.value);
  }

  void _handleSyncError() {
    final message = _authService.syncErrorNotifier.value;
    if (message == null) return;
    _authService.syncErrorNotifier.value = null;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _authService.isSyncingNotifier.removeListener(_handleSyncingChanged);
    _authService.syncErrorNotifier.removeListener(_handleSyncError);
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
      return;
    }
    // 로그인 창을 닫기만 하고 로그인은 완료하지 않은 경우 예외 없이 여기로 돌아오므로
    // 로딩 상태를 풀어준다. 실제로 로그인에 성공했다면 AuthService의 전역 리스너가
    // isSyncingNotifier를 통해 곧바로 다시 로딩 상태로 전환하고 다음 화면으로 넘어간다.
    if (mounted) setState(() => _isLoading = false);
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
