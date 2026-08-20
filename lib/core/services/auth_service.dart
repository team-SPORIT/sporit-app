import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/api.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  // AndroidManifest.xml / Info.plist에 등록된 딥링크 scheme과 반드시 일치해야 함
  static const String _oauthRedirectUrl = 'io.supabase.sporit://login-callback/';

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirectUrl,
    );
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
