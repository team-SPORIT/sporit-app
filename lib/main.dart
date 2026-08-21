import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 로그인 감지 -> 동기화 -> 화면 이동을 앱 전체에서 한 번만, 특정 화면 생명주기와
  // 무관하게 처리하도록 앱 시작 시점에 딱 한 번 등록한다.
  AuthService.instance.startSignInListener();

  runApp(const MyApp());
}
