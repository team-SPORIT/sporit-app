// 운동 시간은 서버가 초 단위로 주고, 화면에는 1:27:40 처럼 보여준다.
String formatSeconds(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final rest = safe % 60;
  return '$hours:${minutes.toString().padLeft(2, '0')}:'
      '${rest.toString().padLeft(2, '0')}';
}
