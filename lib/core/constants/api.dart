import 'package:flutter_dotenv/flutter_dotenv.dart';

class Api {
  Api._();

  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  static String get authSync => '$baseUrl/auth/sync';
}
