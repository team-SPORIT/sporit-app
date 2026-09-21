import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'app_dialog.dart';
import 'app_pill_button.dart';

// 한 줄짜리 값을 입력받는 공통 다이얼로그.
// 확인을 누르면 앞뒤 공백을 없앤 입력값을, 취소하면 null을 돌려준다.
class AppInputDialog extends StatefulWidget {
  const AppInputDialog({
    super.key,
    required this.title,
    required this.hintText,
    required this.confirmText,
    this.initialValue,
    this.maxLength,
  });

  final String title;
  final String hintText;
  final String confirmText;
  final String? initialValue;
  final int? maxLength;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String hintText,
    required String confirmText,
    String? initialValue,
    int? maxLength,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => AppInputDialog(
        title: title,
        hintText: hintText,
        confirmText: confirmText,
        initialValue: initialValue,
        maxLength: maxLength,
      ),
    );
  }

  @override
  State<AppInputDialog> createState() => _AppInputDialogState();
}

class _AppInputDialogState extends State<AppInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // 입력이 비면 확인 버튼을 흐리게 만들어야 해서 변화를 따라간다.
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final hintColor = isDark ? AppColors.bg5 : AppColors.bg4;
    final borderColor = isDark ? AppColors.bg9 : AppColors.bg0;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide(color: borderColor, width: 0.5),
    );

    return AppDialog(
      title: widget.title,
      actions: [
        AppPillButton(
          label: '취소',
          textColor: textColor,
          borderColor: borderColor,
          height: 48,
          onPressed: () => Navigator.pop(context),
        ),
        AppPillButton(
          label: widget.confirmText,
          textColor: AppColors.bg9,
          // 강조 버튼은 선택한 테마 색을 따른다.
          fillColor: _canSubmit
              ? Theme.of(context).colorScheme.primary
              : AppColors.bg3,
          height: 48,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: hintColor,
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
    );
  }
}
