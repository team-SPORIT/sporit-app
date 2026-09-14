import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/info_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/mypage/mypage_screen.dart';

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

// 전환 효과 없이 곧바로 바뀌는 페이지. 탭 전환처럼 화면이 이어져 보여야 하는
// 곳에 쓴다. 아래 routes에서 _fadePage 자리에 그대로 바꿔 끼우면 된다.
//   pageBuilder: (context, state) => instantPage(state, const HomeScreen()),
Page<void> instantPage(GoRouterState state, Widget child) {
  return NoTransitionPage(key: state.pageKey, child: child);
}

final router = GoRouter(
  initialLocation: '/',

  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
    ),
    GoRoute(
      path: '/info',
      pageBuilder: (context, state) => _fadePage(state, const InfoScreen()),
    ),
    GoRoute(
      path: '/mypage',
      pageBuilder: (context, state) => instantPage(state, const MypageScreen()),
    ),
  ],
);
