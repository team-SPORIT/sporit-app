import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';

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
      final isSignInEvent = state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.initialSession;
      if (!isSignInEvent || state.session == null) return;

      setState(() => _isLoading = true);
      try {
        await _authService.syncProfile();
        if (mounted) context.go('/home');
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 처리 중 오류가 발생했어요: $e')),
        );
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인에 실패했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _handleGoogleSignIn,
                child: const Text('Google로 로그인'),
              ),
      ),
    );
  }
}
