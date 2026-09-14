import 'dart:async';

// 스플래시 화면의 최소 노출 시간을 관리한다.
//
// 앱을 켜면 스플래시가 최소 3초는 보이고, 로그인 동기화가 더 오래 걸리면 끝날
// 때까지 더 머무른다. 반대로 동기화가 3초보다 빨리 끝나도 먼저 넘어가지 않는다.
//
// 스플래시에서 다음 화면으로 넘기는 경로가 두 개(스플래시 자체의 /login 이동,
// AuthService 전역 리스너의 /home·/info 이동)라서, 대기 시간도 한 곳에서
// 공유해야 둘이 동시에 화면을 바꾸는 일이 없다.
class SplashGate {
  SplashGate._();

  static final SplashGate instance = SplashGate._();

  static const minimumDuration = Duration(seconds: 3);

  Future<void>? _minimumElapsed;
  bool _isNavigationClaimed = false;

  // runApp 직전에 호출한다. 스플래시가 화면에 뜨는 시점부터 재기 위해서다.
  void start() {
    _minimumElapsed ??= Future<void>.delayed(minimumDuration);
  }

  // 최소 노출 시간이 지날 때까지 기다린다. 이미 지났으면 곧바로 반환한다.
  Future<void> wait() => _minimumElapsed ?? Future<void>.value();

  // 로그인된 사용자를 전역 리스너가 /home(/info)으로 보내기로 한 경우,
  // 스플래시의 /login 이동이 그 위를 덮어쓰지 않도록 미리 표시해둔다.
  void claimNavigation() => _isNavigationClaimed = true;

  bool get isNavigationClaimed => _isNavigationClaimed;
}
