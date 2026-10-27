import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/app_colors.dart';
import '../../../shared/app_palette.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_pill_button.dart';
import '../../../shared/widgets/exercise_chip.dart';

// 서버가 받아주는 그룹 인원 범위 (groups.max_members)
const _minMembers = 2;
const _maxMembers = 50;

// 그룹 이름, 인원, 올릴 수 있는 종목, 색을 한 번에 입력받는 다이얼로그.
class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  static Future<
    ({
      String name,
      int maxMembers,
      String colorKey,
      List<String> exerciseNames,
    })?
  >
  show(BuildContext context) {
    return showDialog<
      ({
        String name,
        int maxMembers,
        String colorKey,
        List<String> exerciseNames,
      })
    >(context: context, builder: (_) => const CreateGroupDialog());
  }

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _membersController = TextEditingController();
  final _exerciseController = TextEditingController();

  // 비워두면 모든 종목 허용, 적어두면 그 종목만 올릴 수 있다.
  final List<String> _exerciseNames = [];
  int _colorIndex = 0;

  int? get _members => int.tryParse(_membersController.text.trim());

  bool get _canSubmit {
    final members = _members;
    return _nameController.text.trim().isNotEmpty &&
        members != null &&
        members >= _minMembers &&
        members <= _maxMembers;
  }

  @override
  void initState() {
    super.initState();
    // 완료 버튼을 켜고 끄기 위해 입력을 따라간다.
    _nameController.addListener(_handleChanged);
    _membersController.addListener(_handleChanged);
  }

  void _handleChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_handleChanged);
    _membersController.removeListener(_handleChanged);
    _nameController.dispose();
    _membersController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final name = _exerciseController.text.trim();
    if (name.isEmpty) return;
    // 같은 이름을 두 번 넣지 않는다.
    if (_exerciseNames.contains(name)) {
      _exerciseController.clear();
      return;
    }
    setState(() {
      _exerciseNames.add(name);
      _exerciseController.clear();
    });
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(context, (
      name: _nameController.text.trim(),
      maxMembers: _members!,
      colorKey: appPalette[_colorIndex].key,
      exerciseNames: List<String>.from(_exerciseNames),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;

    return AppDialog(
      title: '그룹을 만들어 주세요',
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
          _DialogField(
            controller: _nameController,
            hintText: '그룹 이름을 입력',
            textColor: textColor,
            // 서버의 name 컬럼이 VARCHAR(50)이라 입력도 같은 길이로 제한한다.
            maxLength: 50,
          ),
          const SizedBox(height: 12),
          _DialogField(
            controller: _membersController,
            hintText: '인원 ($_minMembers~$_maxMembers)',
            textColor: textColor,
            maxLength: 2,
            isNumber: true,
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: '종목 (안 적으면 전체 허용)', textColor: textColor),
          if (_exerciseNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _exerciseNames)
                  ExerciseChip(
                    label: name,
                    onDelete: () => setState(() => _exerciseNames.remove(name)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _DialogField(
            controller: _exerciseController,
            hintText: '배드민턴, 농구',
            textColor: textColor,
            // 서버의 종목 이름이 VARCHAR(30)이라 같은 길이로 제한한다.
            maxLength: 30,
            onSubmitted: _addExercise,
            suffix: _AddNameButton(onTap: _addExercise, textColor: textColor),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: '색깔을 골라주세요', textColor: textColor),
          const SizedBox(height: 10),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.textColor});

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.hintText,
    required this.textColor,
    required this.maxLength,
    this.isNumber = false,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final Color textColor;
  final int maxLength;
  final bool isNumber;
  final VoidCallback? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: AppColors.bg4, width: 0.5),
    );

    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted?.call(),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      decoration: InputDecoration(
        hintText: hintText,
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
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

class _AddNameButton extends StatelessWidget {
  const _AddNameButton({required this.onTap, required this.textColor});

  final VoidCallback onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.bg4, width: 0.5),
          ),
          child: Icon(Icons.add, size: 16, color: textColor),
        ),
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
