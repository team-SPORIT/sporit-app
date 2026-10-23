import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/group.dart';
import '../../core/services/group_service.dart';
import '../../core/services/workout_session.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/app_input_dialog.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'widgets/create_group_dialog.dart';
import 'widgets/group_card.dart';
import '../calendar/calendar_screen.dart';
import '../record/record_screen.dart';

// 떠 있는 하단 네비게이션의 크기와 화면 아래에서 띄우는 높이.
// 그 아래에 깔리는 화면들이 가려지지 않게 자리를 비울 때 쓴다.
const double homeNavBarHeight = 55;
const double homeNavBarMargin = 24;

// 하단 네비게이션의 세 화면. 선언 순서가 좌 -> 우 배치 순서이고,
// 그대로 PageView의 페이지 순서가 된다(손으로 스와이프해도 같은 순서로 넘어감).
enum HomeTab {
  record(icon: Icons.photo_camera_rounded),
  home(icon: Icons.home_rounded),
  calendar(icon: Icons.calendar_month_rounded);

  const HomeTab({required this.icon});

  final IconData icon;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageController = PageController(initialPage: HomeTab.home.index);
  HomeTab _currentTab = HomeTab.home;

  List<Group> _groups = [];
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();
    // 운동 중에 앱을 껐다 켠 경우, 홈에 머무르지 않고 바로 타이머로 돌려보낸다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (WorkoutSessionController.instance.value != null) {
        context.push('/record/timer');
      }
    });
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await GroupService.instance.fetchMine();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _isLoadingGroups = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleAddAction(TopBarAddAction action) async {
    switch (action) {
      case TopBarAddAction.joinGroup:
        await _handleJoinGroup();
      case TopBarAddAction.createGroup:
        await _handleCreateGroup();
    }
  }

  Future<void> _handleJoinGroup() async {
    final code = await AppInputDialog.show(
      context,
      title: '그룹코드를 입력해주세요',
      hintText: '그룹코드 을 입력',
      confirmText: '완료',
      // 서버가 8자리 초대 코드만 받는다.
      maxLength: 8,
    );
    if (code == null) return;

    try {
      await GroupService.instance.join(code);
      await _loadGroups();
    } catch (e) {
      _showMessage('$e');
    }
  }

  Future<void> _handleCreateGroup() async {
    final created = await CreateGroupDialog.show(context);
    if (created == null) return;

    try {
      await GroupService.instance.create(created.name, created.maxMembers);
      await _loadGroups();
    } catch (e) {
      _showMessage('$e');
    }
  }

  void _goToTab(HomeTab tab) {
    // 탭을 누른 경우에는 중간 페이지가 스쳐 지나가지 않도록 바로 바꾼다.
    // (손으로 스와이프할 때의 움직임은 PageView가 그대로 처리한다.)
    _pageController.jumpToPage(tab.index);
  }

  @override
  Widget build(BuildContext context) {
    // padding은 키보드가 올라오면 0이 되지만 viewPadding은 그대로라,
    // 홈 인디케이터 높이만큼의 여백을 안정적으로 띄울 수 있다.
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppTopBar(onAddPressed: _handleAddAction),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) =>
                setState(() => _currentTab = HomeTab.values[index]),
            children: [
              RecordScreen(isActive: _currentTab == HomeTab.record),
              _HomeBody(
                groups: _groups,
                isLoading: _isLoadingGroups,
                bottomInset:
                    homeNavBarMargin + bottomSafeInset + homeNavBarHeight + 16,
              ),
              const CalendarScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: homeNavBarMargin + bottomSafeInset,
            child: Center(
              child: _HomeBottomNav(currentTab: _currentTab, onTap: _goToTab),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.groups,
    required this.isLoading,
    required this.bottomInset,
  });

  final List<Group> groups;
  final bool isLoading;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: 연속 기록 카드 구현
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  '아직 참여한 그룹이 없어요',
                  style: TextStyle(fontSize: 14, color: AppColors.bg4),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 184,
              ),
              itemBuilder: (context, index) => GroupCard(group: groups[index]),
            ),
        ],
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.currentTab, required this.onTap});

  final HomeTab currentTab;
  final ValueChanged<HomeTab> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // 상하 여백은 선택된 원(47) 기준 4. 선택 안 된 원(39)은 자리 안에서
      // 위아래 4씩 더 들어가므로 8로 보인다.
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg0 : AppColors.bg9,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.bg4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tab in HomeTab.values) ...[
            // 원과 원 사이가 12로 보이게 한다. 자리(47)가 선택 안 된 원(39)보다
            // 양쪽으로 4씩 크므로 그만큼 뺀 값을 넣는다.
            if (tab.index > 0) const SizedBox(width: 8),
            _NavButton(
              tab: tab,
              isSelected: tab == currentTab,
              onTap: () => onTap(tab),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final HomeTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  // 선택된 버튼이 한 단계 크게 그려진다.
  static const double _selectedSize = 47;
  static const double _size = 39;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // 버튼마다 가장 큰 크기(47)의 자리를 고정으로 잡아두고, 그 가운데에서
      // 원만 커지고 작아진다. 원 크기를 그대로 Row에 넣으면 선택이 바뀔 때마다
      // 줄 전체가 다시 배치돼서 옆 아이콘들이 좌우로 밀린다.
      child: SizedBox(
        width: _selectedSize,
        height: _selectedSize,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: isSelected ? _selectedSize : _size,
            height: isSelected ? _selectedSize : _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 선택된 버튼은 사용자가 고른 테마 색을 따른다.
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.bg2,
            ),
            child: Icon(
              tab.icon,
              size: isSelected ? 24 : 20,
              color: AppColors.bg7,
            ),
          ),
        ),
      ),
    );
  }
}
