import '../../shared/app_theme.dart';

// GET /profiles/me 응답
class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    required this.currentStreak,
    required this.theme,
    required this.createdAt,
    this.profileImage,
  });

  final String id;
  final String nickname;
  final int currentStreak;
  final AppTheme theme;

  // 가입일. 캘린더에서 거슬러 올라갈 수 있는 가장 오래된 달의 기준이 된다.
  final DateTime createdAt;
  final String? profileImage;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      theme: AppTheme.fromApiValue(json['theme']),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      profileImage: json['profile_image'] as String?,
    );
  }
}
