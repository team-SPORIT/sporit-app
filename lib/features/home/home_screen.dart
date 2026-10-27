import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/group.dart';
import '../../core/models/weekly_stats.dart';
import '../../core/models/category.dart';
import '../../core/services/category_service.dart';
import '../../core/services/group_service.dart';
import '../../core/services/stats_service.dart';
import '../../core/services/workout_session.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/app_input_dialog.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'widgets/create_group_dialog.dart';
import 'widgets/group_card.dart';
import 'widgets/weekly_summary.dart';
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
  const HomeScreen({super.key, this.initialTab});

  // 특정 탭을 보여달라는 요청. 홈 화면은 한 번 만들어지면 살아 있어서,
  // 기록을 게시하고 돌아올 때처럼 보던 탭을 바꿔줘야 하는 경우에 쓴다.
  final HomeTab? initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _pageController = PageController(
    initialPage: (widget.initialTab ?? HomeTab.home).index,
  );
  late HomeTab _currentTab = widget.initialTab ?? HomeTab.home;

  List<Group> _groups = [];
  WeeklyStats? _weeklyStats;
  List<ExerciseCategory> _categories = [];

  // 그룹 id -> 그 그룹에 올릴 수 있는 종목 이름들. 비어 있으면 전체 허용.
  final Map<String, List<String>> _groupExercises = {};
  bool _isLoading = true;

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
    _load();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final requested = widget.initialTab;
    if (requested == null) return;

    // 기록을 게시하고 돌아온 경우다. 보던 탭이 달랐다면 홈 탭으로 옮기고,
    // 그 사이에 늘어난 기록이 바로 보이도록 다시 받아온다.
    if (requested != _currentTab) _goToTab(requested);
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        GroupService.instance.fetchMine(),
        StatsService.instance.fetchWeekly(),
        CategoryService.instance.fetchMine(),
      ]);
      if (!mounted) return;
      setState(() {
        _groups = results[0] as List<Group>;
        _weeklyStats = results[1] as WeeklyStats;
        _categories = results[2] as List<ExerciseCategory>;
        _isLoading = false;
      });
      await _loadGroupExercises();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 그룹 목록 API는 허용 종목을 주지 않아서 그룹마다 따로 받아온다.
  // 카드가 먼저 그려진 뒤 종목만 채워지므로 목록이 늦게 뜨지는 않는다.
  Future<void> _loadGroupExercises() async {
    final results = await Future.wait(
      _groups.map((group) async {
        try {
          final exercises = await GroupService.instance.fetchExercises(
            group.id,
          );
          return (
            id: group.id,
            names: exercises.allowAll ? <String>[] : exercises.names,
          );
        } catch (_) {
          return (id: group.id, names: <String>[]);
        }
      }),
    );

    if (!mounted) return;
    setState(() {
      for (final result in results) {
        _groupExercises[result.id] = result.names;
      }
    });
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
      await _load();
    } catch (e) {
      _showMessage('$e');
    }
  }

  Future<void> _handleCreateGroup() async {
    final created = await CreateGroupDialog.show(context);
    if (created == null) return;

    try {
      // 이름, 인원, 색, 허용 종목을 한 번에 보낸다.
      await GroupService.instance.create(
        name: created.name,
        maxMembers: created.maxMembers,
        colorKey: created.colorKey,
        exerciseNames: created.exerciseNames,
      );
      await _load();
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
                onRefresh: _load,
                groups: _groups,
                weeklyStats: _weeklyStats,
                categories: _categories,
                groupExercises: _groupExercises,
                isLoading: _isLoading,
                bottomInset:
                    homeNavBarMargin + bottomSafeInset + homeNavBarHeight + 16,
              ),
              CalendarScreen(isActive: _currentTab == HomeTab.calendar),
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
    required this.onRefresh,
    required this.groups,
    required this.weeklyStats,
    required this.categories,
    required this.groupExercises,
    required this.isLoading,
    required this.bottomInset,
  });

  final Future<void> Function() onRefresh;
  final List<Group> groups;
  final WeeklyStats? weeklyStats;
  final List<ExerciseCategory> categories;
  final Map<String, List<String>> groupExercises;
  final bool isLoading;
  final double bottomInset;

  // 주간 집계는 종목 이름만 준다. 선호 운동(카테고리)의 이름이나 거기에 묶인
  // 종목 이름과 맞춰서 색을 가져온다.
  Color _colorOf(String exerciseType) {
    for (final category in categories) {
      if (category.name == exerciseType ||
          category.exerciseNames.contains(exerciseType)) {
        return category.color;
      }
    }
    return AppColors.ex_black;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final byExercise = weeklyStats?.byExercise ?? const [];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        // 내용이 짧아도 아래로 당길 수 있어야 새로고침이 된다.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // 바깥 Column이 왼쪽 정렬이라 폭을 채워줘야 가운데로 온다.
            SizedBox(
              width: double.infinity,
              child: WeeklySummary(stats: weeklyStats),
            ),
            const SizedBox(height: 28),
            _SectionTitle(title: '이번 주 기록', textColor: textColor),
            const SizedBox(height: 12),
            if (byExercise.isEmpty)
              _EmptyText(text: '이번 주 기록이 아직 없어요')
            else
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: byExercise.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final stats = byExercise[index];
                    final color = _colorOf(stats.exerciseType);
                    return WeeklyExerciseCard(
                      stats: stats,
                      color: color,
                      onTap: () => context.push(
                        '/exercise',
                        extra: (exerciseType: stats.exerciseType, color: color),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 28),
            _SectionTitle(title: '그룹', textColor: textColor),
            const SizedBox(height: 12),
            if (groups.isEmpty)
              _EmptyText(text: '아직 참여한 그룹이 없어요')
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (final group in groups) ...[
                      if (group != groups.first) const SizedBox(height: 12),
                      GroupCard(
                        group: group,
                        exerciseNames: groupExercises[group.id],
                        onTap: () => context.push('/group/${group.id}'),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.textColor});

  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.bg4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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
              // 선택된 버튼만 반전시켜 검정 바탕에 흰 아이콘이 되게 한다.
              color: isSelected
                  ? colorScheme.primary
                  : (isDark ? AppColors.bg2 : AppColors.bg7),
            ),
            child: Icon(
              tab.icon,
              size: isSelected ? 24 : 20,
              color: isSelected
                  ? colorScheme.onPrimary
                  : (isDark ? AppColors.bg9 : AppColors.bg0),
            ),
          ),
        ),
      ),
    );
  }
}
