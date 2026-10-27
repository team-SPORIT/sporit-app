import 'package:flutter/material.dart';

// 앱 공통 색상 팔레트.
//
// 서버(common/constants/palette.constants.ts)와 키·색이 같아야 한다. 서버에서
// GET /categories/colors 로도 받을 수 있지만, 그 요청이 실패해도 색을 고를 수
// 있어야 해서 같은 목록을 앱에도 둔다.
class PaletteEntry {
  const PaletteEntry(this.key, this.color);

  final String key;
  final Color color;
}

const appPalette = [
  PaletteEntry('rose', Color(0xFFFF0060)),
  PaletteEntry('coral', Color(0xFFDE5959)),
  PaletteEntry('red', Color(0xFFD21417)),
  PaletteEntry('crimson', Color(0xFFE63946)),
  PaletteEntry('orange', Color(0xFFF6850C)),
  PaletteEntry('amber', Color(0xFFE57300)),
  PaletteEntry('yellow', Color(0xFFFFC300)),
  PaletteEntry('lime', Color(0xFF97BF16)),
  PaletteEntry('sky', Color(0xFF39B1D1)),
  PaletteEntry('blue', Color(0xFF0079FF)),
  PaletteEntry('purple', Color(0xFF7B2CBF)),
  PaletteEntry('black', Color(0xFF202020)),
];
