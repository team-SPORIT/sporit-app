import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_pill_button.dart';

// 서버가 받아주는 그룹 인원 범위 (groups.max_members)
const _minMembers = 2;
const _maxMembers = 50;

// 그룹 이름과 인원을 함께 입력받는 다이얼로그.
class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  static Future<({String name, int maxMembers})?> show(BuildContext context) {
    return showDialog<({String name, int maxMembers})>(
      context: context,
      builder: (_) => const CreateGroupDialog(),
    );
  }

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameController = TextEditingController();
  // 기본값 없이 비워두고 직접 적게 한다.
  final _membersController = TextEditingController();

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
    // 완료 버튼을 켜고 끄기 위해 두 입력 모두 따라간다.
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
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(context, (
      name: _nameController.text.trim(),
      maxMembers: _members!,
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
          textColor: AppColors.bg9,
          fillColor: _canSubmit
              ? Theme.of(context).colorScheme.primary
              : AppColors.bg3,
          height: 48,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
      content: Column(
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
            onSubmitted: _submit,
          ),
        ],
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
  });

  final TextEditingController controller;
  final String hintText;
  final Color textColor;
  final int maxLength;
  final bool isNumber;
  final VoidCallback? onSubmitted;

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
      ),
    );
  }
}
