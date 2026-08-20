import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'
    show LaunchMode, closeInAppWebView;

import '../constants/api.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  // AndroidManifest.xml / Info.plist에 등록된 딥링크 scheme과 반드시 일치해야 함
  static const String _oauthRedirectUrl =
      'io.supabase.sporit://login-callback/';

  static const _oauthInProgressKey = 'oauth_in_progress';

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

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
