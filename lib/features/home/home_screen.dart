import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';

// TODO: 홈 화면 구현 전까지의 임시 플레이스홀더
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await AuthService.instance.signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('홈 페이지'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _handleSignOut(context),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
