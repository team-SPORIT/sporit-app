import 'package:flutter/material.dart';

import '../../../core/models/group.dart';
import '../../../core/models/group_feed.dart';
import '../../../core/utils/duration_format.dart';
import '../../../shared/app_colors.dart';

// 뒤에 겹친 카드가 기울어진 각도(라디안). 음수면 오른쪽 위가 들린다.
const _backCardAngle = -0.084;

// 기울인 뒷장의 귀퉁이가 잘리지 않도록 사방으로 띄워둔다.
const _cardMargin = EdgeInsets.all(10);

// 모서리가 덜 둥글어야 겹친 뒷장의 경계가 또렷하게 보인다.
const _cardRadius = 12.0;

// 그룹 상세의 멤버 한 명 카드.
// 내가 오늘 공유하기 전에는 다른 사람 기록이 잠긴 채로 보인다.
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.share,
    required this.isLocked,
    required this.isMe,
    required this.onTap,
  });

  final GroupMember member;

  // 이 멤버가 오늘 올린 기록. 아직 안 올렸거나 잠겨 있으면 null.
  final FeedShare? share;

  final bool isLocked;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(_cardRadius);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // 뒤에 끝 사진을 살짝 기울여 겹친다. 앞 카드와 같은 자리를 쓰고 기울기만
          // 다르게 해서 네 귀퉁이가 고르게 삐져나오도록 한다.
          Positioned.fill(
            child: Transform.rotate(
              angle: _backCardAngle,
              child: Container(
                margin: _cardMargin,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: radius,
                  image: share == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(share!.endImageUrl),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),
          Container(
            margin: _cardMargin,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: radius,
              image: share == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage(share!.startImageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        AppColors.bg0.withValues(alpha: 0.35),
                        BlendMode.darken,
                      ),
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Center(child: _buildTop(context))),
                Text(
                  member.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.bg9,
                  ),
                ),
                const SizedBox(height: 6),
                _buildDuration(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop(BuildContext context) {
    if (share != null) {
      final comment = share!.comment;
      if (comment == null || comment.isEmpty) {
        return Image.asset('assets/img/icon/icon_wh.png', width: 24);
      }
      return Text(
        comment,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.bg9,
        ),
      );
    }

    // 내 기록은 내가 이미 아는 것이라 잠그지 않는다.
    if (!isMe && isLocked) {
      return const Icon(Icons.lock, size: 28, color: AppColors.bg9);
    }
    return Image.asset('assets/img/icon/icon_wh.png', width: 24);
  }

  Widget _buildDuration() {
    final seconds = share?.durationSec;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/img/icon/icon_wh.png', width: 14),
        const SizedBox(width: 4),
        Text(
          // 잠겨 있으면 남의 운동 시간을 알 수 없다.
          seconds == null ? '--:--' : formatSeconds(seconds),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.bg9,
          ),
        ),
      ],
    );
  }
}
