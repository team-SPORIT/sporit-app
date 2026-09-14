import 'package:flutter/foundation.dart';

import '../../shared/app_theme.dart';

// 선택한 테마를 앱 전체에서 공유한다. 값이 바뀌면 MaterialApp의 강조색과
// 상단바 로고가 즉시 따라 바뀐다. 저장은 서버(profiles.theme)가 담당하고
// 여기서는 현재 값만 들고 있는다.
class ThemeController extends ValueNotifier<AppTheme> {
  ThemeController._() : super(AppTheme.fallback);

  static final ThemeController instance = ThemeController._();
}
