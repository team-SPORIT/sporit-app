// GET /groups/:id/feed 응답
class GroupFeed {
  const GroupFeed({required this.isLocked, required this.shares});

  // 내가 오늘 아직 공유하지 않으면 잠겨서 다른 사람 기록이 내려오지 않는다.
  final bool isLocked;
  final List<FeedShare> shares;

  factory GroupFeed.fromJson(Map<String, dynamic> json) {
    return GroupFeed(
      isLocked: json['locked'] as bool? ?? false,
      shares: (json['records'] as List<dynamic>? ?? [])
          .map((item) => FeedShare.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  FeedShare? shareOf(String userId) {
    for (final share in shares) {
      if (share.authorId == userId) return share;
    }
    return null;
  }
}

// 피드에 올라온 기록 한 건
class FeedShare {
  const FeedShare({
    required this.shareId,
    required this.recordId,
    required this.exerciseType,
    required this.startImageUrl,
    required this.endImageUrl,
    required this.authorId,
    required this.authorNickname,
    required this.reactionCount,
    required this.commentCount,
    required this.durationSec,
    required this.recordDate,
    this.comment,
    this.authorProfileImage,
  });

  final String shareId;
  final String recordId;
  final String exerciseType;
  final String startImageUrl;
  final String endImageUrl;
  final String authorId;
  final String authorNickname;
  final int reactionCount;
  final int commentCount;
  final int durationSec;
  final String recordDate;
  final String? comment;
  final String? authorProfileImage;

  factory FeedShare.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? const {};
    return FeedShare(
      shareId: json['shareId'].toString(),
      recordId: json['recordId'].toString(),
      exerciseType: json['exerciseType'] as String? ?? '',
      startImageUrl: json['startImageUrl'] as String? ?? '',
      endImageUrl: json['endImageUrl'] as String? ?? '',
      authorId: author['id'] as String? ?? '',
      authorNickname: author['nickname'] as String? ?? '',
      authorProfileImage: author['profileImage'] as String?,
      reactionCount: json['reactionCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      durationSec: json['durationSec'] as int? ?? 0,
      // "2026-10-23T00:00:00.000Z" 형태의 KST 날짜. 시간대 변환 없이 앞부분만 쓴다.
      recordDate: (json['recordDate'] as String? ?? '')
          .padRight(10)
          .substring(0, 10),
      comment: json['comment'] as String?,
    );
  }
}
