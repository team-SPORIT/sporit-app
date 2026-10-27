import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/recent_records.dart';
import '../../core/models/workout_record.dart';
import '../../core/services/record_service.dart';
import '../../core/utils/duration_format.dart';
import '../../shared/app_colors.dart';

// 보여줄 주의 개수. 가장 오른쪽이 이번 주다.
// 선호 운동 하나의 기록을 주 단위로 넘겨 보는 화면.
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exerciseType,
    required this.color,
  });

  final String exerciseType;
  final Color color;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  RecentRecords? _recent;
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
      final recent = await RecordService.instance.fetchRecent(
        exerciseType: widget.exerciseType,
      );
      if (!mounted) return;
      setState(() {
        _recent = recent;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = '$e';
      });
    }
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
          widget.exerciseType,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          // TODO: 종목 메뉴(이름/색 수정, 삭제) 구현
          IconButton(icon: const Icon(Icons.more_vert), onPressed: null),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _load, child: const Text('다시 시도')),
                  ],
                ),
              ),
            )
          // 그룹 게시물 상세와 같은 비율로 보이도록 여백을 맞춘다.
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 68),
                child: _PeriodCard(
                  // 기간은 서버가 정한 값을 그대로 쓴다. 앱에서 따로 계산하면
                  // 서버가 담아준 기록과 기간 표시가 어긋난다.
                  from: _recent?.from ?? '',
                  to: _recent?.to ?? '',
                  records: _recent?.records ?? const [],
                  color: widget.color,
                  textColor: textColor,
                ),
              ),
            ),
    );
  }
}

// 최근 기록을 담은 카드. 마지막 기록의 시작 사진이 배경이고, 작은 사진이 끝 사진이다.
class _PeriodCard extends StatefulWidget {
  const _PeriodCard({
    required this.from,
    required this.to,
    required this.records,
    required this.color,
    required this.textColor,
  });

  final String from;
  final String to;
  final List<WorkoutRecord> records;
  final Color color;
  final Color textColor;

  @override
  State<_PeriodCard> createState() => _PeriodCardState();
}

class _PeriodCardState extends State<_PeriodCard> {
  bool _isEndPhotoBackground = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSeconds = widget.records.fold<int>(
      0,
      (sum, record) => sum + record.durationSec,
    );
    final latest = widget.records.isEmpty ? null : widget.records.first;

    final backgroundUrl = latest == null
        ? null
        : (_isEndPhotoBackground ? latest.endImageUrl : latest.startImageUrl);
    final thumbnailUrl = latest == null
        ? null
        : (_isEndPhotoBackground ? latest.startImageUrl : latest.endImageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: isDark ? AppColors.bg1 : AppColors.bg7),
          if (backgroundUrl != null) ...[
            Image.network(
              backgroundUrl,
              key: ValueKey(backgroundUrl),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
            // 사진 위 글씨가 묻히지 않도록 어둡게 덮는다.
            Container(color: AppColors.bg0.withValues(alpha: 0.35)),
          ],
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (latest?.comment case final comment?
                    when comment.isNotEmpty) ...[
                  Text(
                    comment,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: backgroundUrl == null
                          ? widget.textColor
                          : AppColors.bg9,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  _periodLabel(widget.from, widget.to),
                  style: TextStyle(
                    fontSize: 14,
                    color: backgroundUrl == null
                        ? AppColors.bg4
                        : AppColors.bg8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatSeconds(totalSeconds),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: backgroundUrl == null
                        ? widget.textColor
                        : AppColors.bg9,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${widget.records.length}회',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.bg9,
                    ),
                  ),
                ),
                const Spacer(),
                if (thumbnailUrl != null)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      // 작은 사진을 누르면 시작 사진과 끝 사진이 자리를 바꾼다.
                      onTap: () => setState(
                        () => _isEndPhotoBackground = !_isEndPhotoBackground,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          thumbnailUrl,
                          key: ValueKey(thumbnailUrl),
                          width: 110,
                          height: 146,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 110,
                                height: 146,
                                color: AppColors.bg5,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // "2026-10-18" -> "10/18"
  String _periodLabel(String from, String to) {
    String short(String date) {
      if (date.length < 10) return '';
      return '${int.parse(date.substring(5, 7))}/'
          '${int.parse(date.substring(8, 10))}';
    }

    if (from.isEmpty || to.isEmpty) return '';
    return '${short(from)} ~ ${short(to)}';
  }
}
