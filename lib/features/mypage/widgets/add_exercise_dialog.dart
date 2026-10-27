import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';
import '../../../shared/app_palette.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_pill_button.dart';

// 선호 운동을 이름과 색으로 추가하는 다이얼로그.
class AddExerciseDialog extends StatefulWidget {
  const AddExerciseDialog({super.key});

  static Future<({String name, String colorKey})?> show(BuildContext context) {
    return showDialog<({String name, String colorKey})>(
      context: context,
      builder: (_) => const AddExerciseDialog(),
    );
  }

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  final _nameController = TextEditingController();
  int _colorIndex = 0;

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleChanged);
  }

  void _handleChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_handleChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(context, (
      name: _nameController.text.trim(),
      colorKey: appPalette[_colorIndex].key,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: AppColors.bg4, width: 0.5),
    );

    return AppDialog(
      title: '선호하는 운동을 추가 해주세요',
      actions: [
        AppPillButton(
          label: '취소',
          textColor: textColor,
          borderColor: AppColors.bg4,
          height: 48,
          onPressed: () => Navigator.pop(context),
        ),
        AppPillButton(
          label: '완료',
          textColor: Theme.of(context).colorScheme.onPrimary,
          fillColor: _canSubmit
              ? Theme.of(context).colorScheme.primary
              : AppColors.bg3,
          height: 48,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            // 서버의 name 컬럼이 VARCHAR(30)이라 입력도 같은 길이로 제한한다.
            maxLength: 30,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: '배드민턴, 농구',
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.bg5 : AppColors.bg4,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: border,
              focusedBorder: border,
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '색깔을 골라주세요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < appPalette.length; i++)
                _ColorDot(
                  color: appPalette[i].color,
                  isSelected: i == _colorIndex,
                  ringColor: textColor,
                  onTap: () => setState(() => _colorIndex = i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.ringColor,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final Color ringColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 고르지 않은 것도 투명 테두리를 둬서 자리 크기가 변하지 않게 한다.
          border: Border.all(
            color: isSelected ? ringColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
