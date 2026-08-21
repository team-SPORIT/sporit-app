import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'
    show LaunchMode, closeInAppWebView;

import '../constants/api.dart';
import '../routes/app_router.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  // AndroidManifest.xml / Info.plist에 등록된 딥링크 scheme과 반드시 일치해야 함
  static const String _oauthRedirectUrl =
      'io.supabase.sporit://login-callback/';

  static const _oauthInProgressKey = 'oauth_in_progress';

  // 로그인 화면이 로딩 스피너를 보여줄 수 있게 관찰하는 상태.
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier(false);
  // 동기화 실패 메시지. 로그인 화면이 떠 있으면 스낵바로 보여주고 null로 되돌린다.
  final ValueNotifier<String?> syncErrorNotifier = ValueNotifier(null);

  bool _hasStartedSignInListener = false;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // signedIn 딥링크가 GoRouter의 라우팅으로도 잡혀서 스플래시->로그인 화면이 다시
  // 만들어지는 경우가 있다. 그러면 로그인 화면 위젯이 여러 번 새로 생기고, 먼저
  // syncProfile()을 시작한 인스턴스가 응답을 받기 전에 사라져버려서 화면 전환이
  // 안 되는 문제가 있었다. 그래서 이 로그인 감지 -> 동기화 -> 이동 로직을 화면에
  // 묶지 않고, 앱이 켜져있는 내내 한 번만 살아있는 이 서비스에서 처리하고,
  // 이동도 BuildContext 없이 전역 router로 직접 한다.
  void startSignInListener() {
    if (_hasStartedSignInListener) return;
    _hasStartedSignInListener = true;

    authStateChanges.listen((state) async {
      final isSignInEvent =
          state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.initialSession;
      if (!isSignInEvent || state.session == null) return;
      if (isSyncingNotifier.value) return;

      isSyncingNotifier.value = true;
      unawaited(closeOAuthWebView());

      try {
        final isNew = await syncProfile();
        router.go(isNew ? '/info' : '/home');
      } catch (e) {
        syncErrorNotifier.value = '로그인 처리 중 오류가 발생했어요: $e';
      } finally {
        isSyncingNotifier.value = false;
      }
    });
  }

  Future<bool> signInWithGoogle() async {
    // 로그인 팝업이 닫히고 앱으로 돌아왔을 때, 스플래시 화면이 "방금 로그인 버튼을
    // 눌렀던 상황"이라는 걸 구분할 수 있도록 플래그를 남겨둔다.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_oauthInProgressKey, true);

    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirectUrl,
      // 앱 밖 Safari로 나가지 않고, 인앱 팝업(SFSafariViewController/Custom Tabs)으로 띄움
      authScreenLaunchMode: LaunchMode.inAppWebView,
      // SFSafariViewController가 Safari와 구글 로그인 세션을 공유해서, 이게 없으면
      // 계정 선택 화면 없이 이전에 로그인했던 계정으로 자동 진행돼버린다.
      queryParams: const {'prompt': 'select_account'},
    );
  }

  // 스플래시 화면에서 1회성으로 확인: 로그인 버튼을 누른 직후였는지 여부를 읽고 지운다.
  static Future<bool> consumeOAuthInProgressFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final wasInProgress = prefs.getBool(_oauthInProgressKey) ?? false;
    if (wasInProgress) {
      await prefs.remove(_oauthInProgressKey);
    }
    return wasInProgress;
  }

  // 로그인 딥링크를 받은 뒤 호출: iOS에서 인앱 브라우저가 자동으로 안 닫히는 경우가 있어 직접 닫아줌
  Future<void> closeOAuthWebView() async {
    try {
      await closeInAppWebView();
    } catch (_) {
      // 열려있는 인앱 브라우저가 없으면 무시
    }
  }

  // 구글 로그인 성공 직후 백엔드(/auth/sync)에 프로필을 동기화.
  // 이번이 최초 가입인지(isNew) 여부를 반환한다.
  Future<bool> syncProfile() async {
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      throw StateError('로그인 세션이 없습니다.');
    }

    final response = await http.post(
      Uri.parse(Api.authSync),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode >= 400) {
      throw Exception('프로필 동기화 실패 (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['isNew'] as bool? ?? false;
  }

  Future<void> signOut() => _client.auth.signOut();
}
