import 'package:flutter/material.dart';

import '../../shared/app_colors.dart';

// GET /categories 응답의 한 항목. 선호 운동 하나를 이름 + 색으로 나타낸다.
class ExerciseCategory {
  const ExerciseCategory({
    required this.id,
    required this.name,
    required this.colorKey,
    required this.colorHex,
    required this.exerciseNames,
  });

  final String id;
  final String name;

  // 서버에는 팔레트 키만 저장되고 hex는 응답으로 함께 내려온다.
  final String colorKey;
  final String? colorHex;

  final List<String> exerciseNames;

  Color get color => parseHexColor(colorHex);

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) {
    return ExerciseCategory(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      colorKey: json['color'] as String? ?? '',
      colorHex: json['colorHex'] as String?,
      exerciseNames: (json['exerciseNames'] as List<dynamic>? ?? [])
          .map((name) => name as String)
          .toList(),
    );
  }
}

// GET /categories/colors 의 한 항목
class PaletteColor {
  const PaletteColor({required this.key, required this.hex});

  final String key;
  final String hex;

  Color get color => parseHexColor(hex);

  factory PaletteColor.fromJson(Map<String, dynamic> json) {
    return PaletteColor(
      key: json['key'] as String? ?? '',
      hex: json['hex'] as String? ?? '',
    );
  }
}

// "#0079FF" 형태를 Color로. 알 수 없는 값이면 검정으로 둔다.
Color parseHexColor(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) {
    return AppColors.ex_black;
  }
  final value = int.tryParse(hex.substring(1), radix: 16);
  if (value == null) return AppColors.ex_black;
  return Color(0xFF000000 | value);
}
