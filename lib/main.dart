import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/splash_gate.dart';
import 'core/services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 스플래시부터 저장해둔 테마로 그릴 수 있게, 로그인 동기화보다 먼저 읽어둔다.
  await ThemeController.instance.load();

  // 로그인 감지 -> 동기화 -> 화면 이동을 앱 전체에서 한 번만, 특정 화면 생명주기와
  // 무관하게 처리하도록 앱 시작 시점에 딱 한 번 등록한다.
  AuthService.instance.startSignInListener();

  // 스플래시 최소 노출 시간은 화면이 실제로 뜨는 이 시점부터 잰다.
  SplashGate.instance.start();

  runApp(const MyApp());
}
