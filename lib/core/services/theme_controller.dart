import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/app_theme.dart';

// 선택한 테마를 앱 전체에서 공유한다. 값이 바뀌면 MaterialApp의 강조색과
// 상단바 로고, 스플래시 배경색이 즉시 따라 바뀐다.
//
// 원본은 서버(profiles.theme)지만, 스플래시는 로그인 동기화 응답을 받기 전에
// 이미 떠 있어야 해서 값이 바뀔 때마다 기기에도 캐시해둔다. 앱을 켜면 캐시된
// 값으로 먼저 그리고, 서버 응답이 오면 그 값으로 덮어쓴다.
class ThemeController extends ValueNotifier<AppTheme> {
  ThemeController._() : super(AppTheme.fallback);

  static final ThemeController instance = ThemeController._();

  static const _storageKey = 'app_theme';

  // 앱 시작 시 runApp 전에 한 번 호출한다.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) super.value = AppTheme.fromApiValue(saved);
    } catch (_) {
      // 캐시를 못 읽으면 기본 테마로 시작한다.
    }
  }

  @override
  set value(AppTheme newValue) {
    if (newValue == super.value) return;
    super.value = newValue;
    unawaited(_persist(newValue));
  }

  Future<void> _persist(AppTheme theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, theme.apiValue);
    } catch (_) {
      // 캐시 저장에 실패해도 서버에 저장된 값이 원본이므로 무시한다.
    }
  }
}
