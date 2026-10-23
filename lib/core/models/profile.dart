import '../../shared/app_theme.dart';
import '../utils/kst_date.dart';

// GET /profiles/me 응답
class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    required this.currentStreak,
    required this.theme,
    required this.createdAt,
    this.lastRecordDate,
    this.profileImage,
  });

  final String id;
  final String nickname;
  final int currentStreak;
  final AppTheme theme;

  // 가입일. 캘린더에서 거슬러 올라갈 수 있는 가장 오래된 달의 기준이 된다.
  final DateTime createdAt;

  // 마지막으로 운동을 기록한 날(KST). 기록이 없으면 null.
  final DateTime? lastRecordDate;

  // 서버의 current_streak은 기록을 올릴 때만 갱신돼서, 며칠 쉬어도 예전 값이
  // 그대로 남아 있다. 마지막 기록일을 보고 아직 살아 있는 기록인지 가려낸다.
  int get effectiveStreak {
    final last = lastRecordDate;
    if (last == null) return 0;

    final today = kstToday();
    final yesterday = today.subtract(const Duration(days: 1));
    // 오늘 했으면 이어지는 중이고, 어제까지 했으면 오늘 하면 이어진다.
    if (last == today || last == yesterday) return currentStreak;
    return 0;
  }

  bool get hasRecordedToday => lastRecordDate == kstToday();
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
      lastRecordDate: _parseDateOnly(json['last_record_date'] as String?),
      profileImage: json['profile_image'] as String?,
    );
  }
}

// "2026-10-23T00:00:00.000Z" 형태의 KST 날짜에서 날짜만 읽는다.
// DateTime.parse로 바꾸면 기기 시간대에 따라 하루 밀릴 수 있다.
DateTime? _parseDateOnly(String? value) {
  if (value == null || value.length < 10) return null;
  return DateTime.tryParse(value.substring(0, 10));
}
