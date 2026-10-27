import 'package:flutter/material.dart';

import '../../core/models/profile.dart';
import '../../core/services/profile_controller.dart';
import '../../core/models/category.dart';
import '../../core/services/category_service.dart';
import '../../core/services/record_service.dart';
import '../../core/utils/kst_date.dart';
import '../../shared/app_colors.dart';

// 기록 횟수에 따른 농도 단계. 하루 1회가 대부분이라 단계를 잘게 쪼개면 거의 모든
// 칸이 같은 색이 되므로 3단계로만 나눈다. 값은 배경색과 테마색을 섞는 비율이라
// 어떤 테마를 골라도, 다크/라이트 어디서도 같은 리듬이 유지된다.
const _fillStrengths = [0.45, 0.7, 1.0];

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.isActive = true});

  // 홈에서 캘린더 탭이 선택돼 있는지. 탭으로 돌아올 때마다 다시 불러와야
  // 방금 올린 기록이 바로 보인다.
  final bool isActive;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DateTime _today = kstToday();

  // 한 번 받은 달은 다시 요청하지 않는다(탭을 다시 열 때만 갱신).
  // 'YYYY-MM' -> 일자별 그날 한 종목 이름들
  final Map<String, Map<int, List<String>>> _daysByMonth = {};
  List<ExerciseCategory> _categories = [];
  final Set<String> _requested = {};
  String? _loadError;

  static String _keyOf(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다른 탭에 있는 동안 기록이 늘었을 수 있으므로 돌아올 때 다시 받아온다.
    if (widget.isActive && !oldWidget.isActive) _refreshLoadedMonths();
  }

  Future<void> _loadMonth(DateTime month) async {
    // 이미 받아온 달은 다시 요청하지 않는다(탭을 다시 열 때만 갱신).
    if (!_requested.add(_keyOf(month))) return;
    await _fetchMonth(month);
  }

  // 종목 색을 알아야 칸을 칠할 수 있다.
  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.instance.fetchMine();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      // 색을 못 받으면 기본색으로 칠한다.
    }
  }

  // 종목 이름에 맞는 색. 못 찾으면 검정.
  Color _colorOf(String exerciseType) {
    for (final category in _categories) {
      if (category.name == exerciseType ||
          category.exerciseNames.contains(exerciseType)) {
        return category.color;
      }
    }
    return AppColors.ex_black;
  }

  Future<void> _refreshLoadedMonths() async {
    final keys = {..._requested, ..._daysByMonth.keys};
    await Future.wait(
      keys.map((key) {
        final parts = key.split('-');
        return _fetchMonth(DateTime(int.parse(parts[0]), int.parse(parts[1])));
      }),
    );
  }

  Future<void> _fetchMonth(DateTime month) async {
    final key = _keyOf(month);
    try {
      final days = await RecordService.instance.fetchMonthlyDays(
        month.year,
        month.month,
      );
      if (!mounted) return;
      setState(() {
        _daysByMonth[key] = days;
        _loadError = null;
      });
    } catch (e) {
      // 실패한 달은 다시 보일 때 재시도할 수 있게 표시를 지우고, 왜 비어 있는지
      // 알 수 있도록 화면에도 알린다.
      _requested.remove(key);
      if (mounted) setState(() => _loadError = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return ValueListenableBuilder<Profile?>(
      valueListenable: ProfileController.instance,
      builder: (context, profile, _) {
        // 가입한 달부터 이번 달까지만 거슬러 올라갈 수 있다.
        final joined = profile?.createdAt ?? _today;
        final monthCount =
            (_today.year * 12 + _today.month) -
            (joined.year * 12 + joined.month) +
            1;

        final listView = ListView.builder(
          // 이번 달이 맨 아래에 오고, 위로 스와이프하면 과거로 거슬러 올라간다.
          reverse: true,
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            // 떠 있는 하단 네비게이션에 마지막 줄이 가리지 않도록 띄운다.
            24 + bottomSafeInset + 55 + 16,
          ),
          itemCount: monthCount < 1 ? 1 : monthCount,
          itemBuilder: (context, index) {
            final month = DateTime(_today.year, _today.month - index);
            return _MonthSection(
              month: month,
              today: _today,
              days: _daysByMonth[_keyOf(month)],
              colorOf: _colorOf,
              onVisible: () => _loadMonth(month),
            );
          },
        );

        final error = _loadError;
        if (error == null) return listView;

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.redWaring,
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.bg9),
              ),
            ),
            Expanded(child: listView),
          ],
        );
      },
    );
  }
}

// 한 달치 달력. 화면에 들어올 때 그 달의 기록을 불러오도록 알린다.
class _MonthSection extends StatefulWidget {
  const _MonthSection({
    required this.month,
    required this.today,
    required this.days,
    required this.colorOf,
    required this.onVisible,
  });

  final DateTime month;
  final DateTime today;
  // 일자별 그날 한 종목 이름들. 아직 못 받았으면 null.
  final Map<int, List<String>>? days;

  // 종목 이름 -> 색
  final Color Function(String) colorOf;
  final VoidCallback onVisible;

  @override
  State<_MonthSection> createState() => _MonthSectionState();
}

class _MonthSectionState extends State<_MonthSection> {
  @override
  void initState() {
    super.initState();
    // ListView.builder가 화면에 보일 때쯤 만들어주므로, 여기서 요청하면
    // 스크롤해서 다다른 달만 불러오게 된다.
    widget.onVisible();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final background = isDark ? AppColors.bg0 : AppColors.bg9;

    final month = widget.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // 일요일을 한 주의 첫 칸으로 둔다(DateTime은 월=1 ... 일=7).
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday % 7;
    final rowCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          _monthLabel(month, widget.today),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 24),
        for (var row = 0; row < rowCount; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = row * 7 + column - leadingBlanks + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const SizedBox(height: 40);
                      }
                      return _DayCell(
                        day: day,
                        exerciseTypes: widget.days?[day] ?? const [],
                        colorOf: widget.colorOf,
                        isToday:
                            month.year == widget.today.year &&
                            month.month == widget.today.month &&
                            day == widget.today.day,
                        background: background,
                        textColor: textColor,
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  // 해가 바뀌면 몇 년도인지 알 수 있어야 해서 올해가 아니거나 1월이면 연도를 붙인다.
  String _monthLabel(DateTime month, DateTime today) {
    if (month.year != today.year || month.month == 1) {
      return '${month.year}년 ${month.month}월';
    }
    return '${month.month}월';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.exerciseTypes,
    required this.colorOf,
    required this.isToday,
    required this.background,
    required this.textColor,
  });

  final int day;

  // 그날 한 운동들. 비어 있으면 기록이 없는 날이다.
  final List<String> exerciseTypes;

  final Color Function(String) colorOf;
  final bool isToday;
  final Color background;
  final Color textColor;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final fill = _fillColor();
    // 라임처럼 밝은 색에서도 숫자가 읽히도록 칠한 색의 밝기를 보고 고른다.
    final dayColor = fill == null
        ? textColor
        : (fill.computeLuminance() > 0.5 ? AppColors.bg1 : AppColors.bg9);

    return Center(
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          // 오늘은 칠해졌든 비었든 테두리로 구분한다.
          border: isToday ? Border.all(color: textColor, width: 1.5) : null,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 15,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: dayColor,
          ),
        ),
      ),
    );
  }

  // 그날 첫 운동의 종목 색으로 칠하고, 여러 번 했으면 더 진하게 한다.
  Color? _fillColor() {
    if (exerciseTypes.isEmpty) return null;
    final color = colorOf(exerciseTypes.first);
    final strength =
        _fillStrengths[exerciseTypes.length.clamp(1, _fillStrengths.length) -
            1];
    return Color.lerp(background, color, strength);
  }
}
