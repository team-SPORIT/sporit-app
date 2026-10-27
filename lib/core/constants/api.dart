import 'package:flutter_dotenv/flutter_dotenv.dart';

class Api {
  Api._();

  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  static String get authSync => '$baseUrl/auth/sync';
  static String get profilesMe => '$baseUrl/profiles/me';
  static String get profilesAvatar => '$baseUrl/profiles/me/avatar';
  static String get groups => '$baseUrl/groups';
  static String get groupsJoin => '$baseUrl/groups/join';
  static String groupById(String id) => '$baseUrl/groups/$id';
  static String groupFeed(String id) => '$baseUrl/groups/$id/feed';
  static String groupExercises(String id) => '$baseUrl/groups/$id/exercises';
  static String get shares => '$baseUrl/shares';
  static String get records => '$baseUrl/records';
  static String get recordsMe => '$baseUrl/records/me';
  static String get exercises => '$baseUrl/exercises';
  static String exerciseById(String id) => '$baseUrl/exercises/$id';
  static String get exercisesSelectable => '$baseUrl/exercises/selectable';
  static String exerciseGroups(String id) => '$baseUrl/exercises/$id/groups';
  static String get statsWeekly => '$baseUrl/stats/weekly';
  static String get recordsRecent => '$baseUrl/records/me/recent';
  static String get categories => '$baseUrl/categories';
  static String get categoryColors => '$baseUrl/categories/colors';
  static String categoryById(String id) => '$baseUrl/categories/$id';
}
