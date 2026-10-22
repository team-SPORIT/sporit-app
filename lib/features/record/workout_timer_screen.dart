import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/workout_session.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/app_pill_button.dart';

const _cheerText = '열정이 열심히 불타고 있어요!!';

// 운동 중 화면. 시작 직후에는 3까지 세고, 그 뒤로는 경과 시간을 보여준다.
// 화면을 나갔다 들어와도, 앱을 껐다 켜도 진행 중인 운동이 그대로 이어진다.
class WorkoutTimerScreen extends StatefulWidget {
  const WorkoutTimerScreen({super.key, this.startPhotoPath});

  // 값이 있으면 막 찍은 시작 사진이라는 뜻이다. 카운트다운을 보여준 뒤
  // 그 사진으로 운동을 시작한다(세는 3초가 운동 시간에 포함되지 않도록).
  final String? startPhotoPath;

  @override
  State<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen> {
  static const _countdownSteps = 3;

  Timer? _ticker;
  Timer? _countdownTimer;
  int _countdownStep = 1;
  late bool _isCountingDown = widget.startPhotoPath != null;

  @override
  void initState() {
    super.initState();
    if (_isCountingDown) {
      _startCountdown();
    } else {
      _startTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownStep >= _countdownSteps) {
        timer.cancel();
        _finishCountdown();
        return;
      }
      setState(() => _countdownStep++);
    });
  }

  // 다 세고 난 지금을 운동 시작 시각으로 삼는다. 시작 사진을 보관 폴더로
  // 옮기는 동안 기다려야 한다. 기다리지 않고 화면을 바꾸면 아직 운동이 없는
  // 상태로 그려져서 홈으로 되돌려보내진다.
  Future<void> _finishCountdown() async {
    await WorkoutSessionController.instance.start(widget.startPhotoPath!);
    if (!mounted) return;
    setState(() => _isCountingDown = false);
    _startTicker();
  }

  // 경과 시간은 시작 시각에서 계산하므로, 이 타이머는 화면을 다시 그리기만 한다.
  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _handlePause() {
    WorkoutSessionController.instance.pause();
    setState(() {});
  }

  void _handleResume() {
    WorkoutSessionController.instance.resume();
    setState(() {});
  }

  void _handleFinish() => context.push('/record/finish');

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final session = WorkoutSessionController.instance.value;

    // 기록을 마치고 돌아오는 순간처럼 운동이 끝난 경우에는 홈으로 돌려보낸다.
    // (카운트다운 중에는 아직 운동이 시작되지 않았으므로 그대로 둔다.)
    if (session == null && !_isCountingDown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return Scaffold(backgroundColor: themeColor);
    }

    return PopScope(
      // 운동 중에 뒤로 가기로 빠져나가면 진행 상황을 놓치게 되므로 막는다.
      canPop: false,
      child: Scaffold(
        backgroundColor: themeColor,
        body: SafeArea(
          child: _isCountingDown
              ? _CountdownBody(step: _countdownStep)
              : _RunningBody(
                  session: session!,
                  onPause: _handlePause,
                  onResume: _handleResume,
                  onFinish: _handleFinish,
                ),
        ),
      ),
    );
  }
}

class _CountdownBody extends StatelessWidget {
  const _CountdownBody({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$step',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.w800,
              color: AppColors.bg9,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            _cheerText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.bg9),
          ),
        ],
      ),
    );
  }
}

class _RunningBody extends StatelessWidget {
  const _RunningBody({
    required this.session,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final WorkoutSession session;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return Column(
      children: [
        const Spacer(),
        Image.asset('assets/img/icon/icon_wh.png', width: 40),
        const SizedBox(height: 16),
        Text(
          formatWorkoutDuration(session.elapsed),
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: AppColors.bg9,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          _cheerText,
          style: TextStyle(fontSize: 13, color: AppColors.bg9),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomSafeInset),
          child: session.isPaused
              ? Row(
                  children: [
                    Expanded(
                      child: AppPillButton(
                        label: '이어하기',
                        textColor: AppColors.bg9,
                        fillColor: AppColors.bg0,
                        onPressed: onResume,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPillButton(
                        label: '운동끝내기',
                        textColor: AppColors.bg9,
                        fillColor: AppColors.redWaring,
                        onPressed: onFinish,
                      ),
                    ),
                  ],
                )
              : AppPillButton(
                  label: '일시 정지하기',
                  textColor: AppColors.bg9,
                  fillColor: AppColors.bg0,
                  onPressed: onPause,
                ),
        ),
      ],
    );
  }
}

// 1:27:40 처럼 시:분:초로, 한 시간이 안 되면 분:초로 보여준다.
String formatWorkoutDuration(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 1 << 31);
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;
  final paddedSeconds = remainingSeconds.toString().padLeft(2, '0');

  if (hours == 0) return '$minutes:$paddedSeconds';
  return '$hours:${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
}
