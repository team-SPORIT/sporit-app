import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/workout_session.dart';
import '../../core/utils/duration_format.dart';
import '../../shared/app_colors.dart';

const _cheerText = '열정이 열심히 불타고 있어요!!';

// 카운트다운은 숫자가 올라갈수록 불이 세지듯 색이 바뀐다.
const _countdownColors = [
  AppColors.fire_yellow,
  AppColors.fire_orange,
  AppColors.fire_red,
];

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

  // 다 세고 난 지금을 운동 시작 시각으로 삼는다.
  Future<void> _finishCountdown() async {
    // 시작 사진을 보관 폴더로 옮기는 동안 기다린다. 기다리지 않고 화면을 바꾸면
    // 아직 운동이 없는 상태로 그려져서 홈으로 되돌려보내진다.
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = _isCountingDown
        ? _countdownColors[(_countdownStep - 1).clamp(
            0,
            _countdownColors.length - 1,
          )]
        : (isDark ? AppColors.bg0 : AppColors.bg8);

    return PopScope(
      // 운동 중에 뒤로 가기로 빠져나가면 진행 상황을 놓치게 되므로 막는다.
      canPop: false,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          // Scaffold는 body에 "최대 이만큼"만 알려주기 때문에, 펴주지 않으면
          // Column이 가장 넓은 자식 크기로 줄어들어 내용이 왼쪽에 몰린다.
          child: SizedBox.expand(
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
              fontFamily: 'Infinite',
              fontSize: 150,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;

    return Column(
      children: [
        const Spacer(flex: 3),
        Image.asset(
          // 흰색 아이콘에 색을 입혀서 불꽃을 주황으로 만든다.
          'assets/img/icon/icon_wh.png',
          width: 72,
          color: AppColors.fire_orange,
        ),
        const SizedBox(height: 20),
        Text(
          formatSeconds(session.elapsed.inSeconds),
          style: TextStyle(
            fontFamily: 'Infinite',
            fontSize: 52,
            color: textColor,
          ),
        ),
        const Spacer(flex: 4),
        if (session.isPaused)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(
                onTap: onResume,
                borderColor: AppColors.bg2,
                child: const _PlayIcon(color: AppColors.bg2),
              ),
              const SizedBox(width: 28),
              _CircleButton(
                onTap: onFinish,
                borderColor: AppColors.stop_red,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.stop_red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          )
        else
          _CircleButton(
            onTap: onPause,
            borderColor: AppColors.bg2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 2; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Container(
                    width: 11,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ],
            ),
          ),
        SizedBox(height: 80 + bottomSafeInset),
      ],
    );
  }
}

// 테두리만 있는 둥근 버튼. 안에 재생/일시정지/정지 모양이 들어간다.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.onTap,
    required this.borderColor,
    required this.child,
  });

  final VoidCallback onTap;
  final Color borderColor;
  final Widget child;

  static const double _size = 120;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 3),
        ),
        child: child,
      ),
    );
  }
}

// 재생 삼각형. 아이콘 폰트 대신 직접 그려서 크기와 비율을 맞춘다.
class _PlayIcon extends StatelessWidget {
  const _PlayIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(34, 38),
      painter: _PlayIconPainter(color: color),
    );
  }
}

class _PlayIconPainter extends CustomPainter {
  const _PlayIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      // 모서리를 살짝 둥글게 해서 시안의 삼각형과 같은 느낌을 낸다.
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    canvas
      ..drawPath(path, paint)
      ..drawPath(path, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_PlayIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
