import '../../shared/app_theme.dart';

// GET /profiles/me 응답
class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    required this.currentStreak,
    required this.theme,
    this.profileImage,
  });

  final String id;
  final String nickname;
  final int currentStreak;
  final AppTheme theme;
  final String? profileImage;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      theme: AppTheme.fromApiValue(json['theme']),
      profileImage: json['profile_image'] as String?,
    );
  }
}
