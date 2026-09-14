import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';

// TODO: 마이페이지 구현 전까지의 임시 플레이스홀더
class MypageScreen extends StatelessWidget {
  const MypageScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await AuthService.instance.signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('마이페이지'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleSignOut(context),
          child: const Text('로그아웃'),
        ),
      ),
    );
  }
}
