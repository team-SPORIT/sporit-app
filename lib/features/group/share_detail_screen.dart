import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/group_feed.dart';
import '../../core/utils/duration_format.dart';
import '../../shared/app_colors.dart';

// 작은 사진 자리의 크기와 가장자리 여백.
const _thumbnailWidth = 110.0;
const _thumbnailHeight = 146.0;
const _thumbnailMargin = 12.0;

// 그룹 피드의 기록 한 건 상세.
// 시작 사진이 배경이고, 오른쪽 아래의 작은 사진을 누르면 둘이 자리를 바꾼다.
class ShareDetailScreen extends StatefulWidget {
  const ShareDetailScreen({super.key, required this.share});

  final FeedShare share;

  @override
  State<ShareDetailScreen> createState() => _ShareDetailScreenState();
}

class _ShareDetailScreenState extends State<ShareDetailScreen> {
  bool _isEndPhotoBackground = false;

  FeedShare get share => widget.share;

  String get _backgroundUrl =>
      _isEndPhotoBackground ? share.endImageUrl : share.startImageUrl;

  String get _thumbnailUrl =>
      _isEndPhotoBackground ? share.startImageUrl : share.endImageUrl;

  void _swapPhotos() =>
      setState(() => _isEndPhotoBackground = !_isEndPhotoBackground);

  void _showNotReady(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('아직 준비 중인 기능이에요')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            _AuthorAvatar(imageUrl: share.authorProfileImage),
            const SizedBox(width: 8),
            Text(
              share.authorNickname,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showNotReady(context),
          ),
        ],
      ),
      body: SafeArea(
        // 갤럭시의 하단 제스처 바에 사진이 가리지 않도록 한다.
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 68),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 두 사진이 각각 "큰 자리"와 "작은 자리"를 오가며 서로 바꾼다.
                final bigRect = Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final smallRect = Rect.fromLTWH(
                  constraints.maxWidth - _thumbnailWidth - _thumbnailMargin,
                  constraints.maxHeight - _thumbnailHeight - _thumbnailMargin,
                  _thumbnailWidth,
                  _thumbnailHeight,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 작은 사진이 큰 사진 위에 오도록 배경이 되는 쪽을 먼저 그린다.
                    // 키가 있어서 순서가 바뀌어도 애니메이션은 이어진다.
                    for (final url in [_backgroundUrl, _thumbnailUrl])
                      _SwappablePhoto(
                        key: ValueKey(url),
                        imageUrl: url,
                        rect: url == _backgroundUrl ? bigRect : smallRect,
                        isBackground: url == _backgroundUrl,
                        onTap: _swapPhotos,
                      ),
                    _buildContent(context),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (share.comment case final comment? when comment.isNotEmpty) ...[
            Text(
              comment,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.bg9,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            _formatDate(share.recordDate),
            style: const TextStyle(fontSize: 14, color: AppColors.bg9),
          ),
          const SizedBox(height: 4),
          Text(
            formatSeconds(share.durationSec),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.bg9,
            ),
          ),
          const SizedBox(height: 16),
          _ExerciseBadge(label: share.exerciseType),
          const Spacer(),
          Row(
            children: [
              _ActionButton(
                icon: Icons.favorite,
                count: share.reactionCount,
                onTap: () => _showNotReady(context),
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.chat_bubble,
                count: share.commentCount,
                onTap: () => _showNotReady(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.length < 10) return '';
    final month = int.tryParse(isoDate.substring(5, 7)) ?? 0;
    final day = int.tryParse(isoDate.substring(8, 10)) ?? 0;
    return '$month/$day';
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.bg4,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? null
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
    );
  }
}

class _ExerciseBadge extends StatelessWidget {
  const _ExerciseBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: AppColors.bg9),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(fontSize: 14, color: AppColors.bg9),
            ),
          ],
        ],
      ),
    );
  }
}

// 큰 자리와 작은 자리를 오가는 사진. 자리를 옮기는 모습이 그대로 보인다.
class _SwappablePhoto extends StatelessWidget {
  const _SwappablePhoto({
    super.key,
    required this.imageUrl,
    required this.rect,
    required this.isBackground,
    required this.onTap,
  });

  final String imageUrl;
  final Rect rect;
  final bool isBackground;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: _duration,
      curve: Curves.easeInOut,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        // 작은 사진을 누르면 두 사진이 자리를 바꾼다.
        onTap: isBackground ? null : onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: AppColors.bg2),
              ),
              // 배경일 때만 글씨가 묻히지 않게 어둡게 덮는다.
              AnimatedOpacity(
                duration: _duration,
                opacity: isBackground ? 1 : 0,
                child: Container(color: AppColors.bg0.withValues(alpha: 0.35)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
