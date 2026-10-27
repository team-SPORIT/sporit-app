import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/group.dart';
import '../../core/models/group_feed.dart';
import '../../core/services/group_service.dart';
import '../../core/services/profile_controller.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_pill_button.dart';
import 'widgets/member_card.dart';

// 그룹 상세. 멤버마다 오늘의 기록을 카드로 보여준다.
class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  Group? _group;
  GroupFeed? _feed;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        GroupService.instance.fetchOne(widget.groupId),
        GroupService.instance.fetchFeed(widget.groupId),
      ]);
      if (!mounted) return;
      setState(() {
        _group = results[0] as Group;
        _feed = results[1] as GroupFeed;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _isLoading = false;
      });
    }
  }

  // 다른 사람을 초대할 때 쓰는 코드를 보여준다.
  Future<void> _showInviteCode() async {
    final group = _group;
    if (group == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: '그룹 코드',
        actions: [
          AppPillButton(
            label: '복사',
            textColor: textColor,
            borderColor: AppColors.bg4,
            height: 48,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: group.inviteCode));
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('그룹 코드를 복사했어요')));
            },
          ),
          AppPillButton(
            label: '확인',
            textColor: Theme.of(dialogContext).colorScheme.onPrimary,
            fillColor: Theme.of(dialogContext).colorScheme.primary,
            height: 48,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.bg4, width: 0.5),
              ),
              child: Text(
                group.inviteCode,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  // 코드를 또박또박 읽을 수 있게 글자 사이를 띄운다.
                  letterSpacing: 4,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '이 코드를 전달하면 그룹에 참여할 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.bg4),
            ),
          ],
        ),
      ),
    );
  }

  // 운동 시작 화면은 하단 네비게이션 없이 전체 화면으로 띄운다.
  Future<void> _startWorkout() async {
    await context.push('/record/start');
    if (mounted) _load();
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
        title: Text(
          _group?.name ?? '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          // TODO: 그룹 탈퇴 등 나머지 메뉴 추가
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _group == null ? null : _showInviteCode,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startWorkout,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: AppColors.bg9,
        shape: const CircleBorder(),
        child: const Icon(Icons.play_arrow_rounded, size: 32),
      ),
      body: _buildBody(textColor),
    );
  }

  Widget _buildBody(Color textColor) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final error = _loadError;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final group = _group!;
    final feed = _feed!;
    final myId = ProfileController.instance.value?.id;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: group.members.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 170,
      ),
      itemBuilder: (context, index) {
        final member = group.members[index];
        final share = feed.shareOf(member.id);
        final isMe = member.id == myId;

        return MemberCard(
          member: member,
          share: share,
          isLocked: feed.isLocked,
          isMe: isMe,
          // 기록이 있을 때만 상세로 들어간다. 운동 시작은 아래 재생 버튼이 맡는다.
          onTap: share == null
              ? () {}
              : () => context.push('/group/${group.id}/share', extra: share),
        );
      },
    );
  }
}
