import 'package:flutter/material.dart';

import 'app_colors.dart';

// 이번 주 운동 시간에 따라 불꽃 색이 올라간다. 불이 뜨거워질수록 노랑 -> 빨강 ->
// 보라 -> 파랑으로 가는 실제 불꽃 색 순서를 따른다.
//
// 기준 시간은 주간 누적이다. 세계보건기구 권장 운동량이 주 2시간 30분이라
// 그 지점을 중간쯤에 두고, 위쪽은 꾸준히 하는 사람이 올라가볼 만한 간격으로 잡았다.
class _FireLevel {
  const _FireLevel(this.minMinutes, this.color);

  final int minMinutes;
  final Color color;
}

const _fireLevels = [
  _FireLevel(0, AppColors.fire_yellow), // 시작
  _FireLevel(60, AppColors.fire_orange), // 1시간
  _FireLevel(150, AppColors.fire_coral), // 2시간 30분 (권장 운동량)
  _FireLevel(240, AppColors.fire_red), // 4시간
  _FireLevel(360, AppColors.fire_violet), // 6시간
  _FireLevel(480, AppColors.fire_purple), // 8시간
  _FireLevel(660, AppColors.fire_navy), // 11시간
  _FireLevel(900, AppColors.fire_blue), // 15시간
];

// 이번 주 운동 시간(초)에 해당하는 불꽃 색
Color fireColorForSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  var color = _fireLevels.first.color;
  for (final level in _fireLevels) {
    if (minutes < level.minMinutes) break;
    color = level.color;
  }
  return color;
}
