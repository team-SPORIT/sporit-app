import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/api.dart';
import '../../shared/app_colors.dart';

const _totalSteps = 2;

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => InfoScreenState();
}

class InfoScreenState extends State<InfoScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _sportController = TextEditingController();
  final _sportFocusNode = FocusNode();
  final List<String> _sportTags = [];

  int _currentPage = 0;
  bool _isCompleted = false;
  bool _isSaving = false;

  bool get _isLastPage => _currentPage == _totalSteps - 1;

  double get _progress => _isCompleted ? 1 : _currentPage / _totalSteps;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _sportController.dispose();
    _sportFocusNode.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _addSportTag() {
    final value = _sportController.text.trim();
    if (value.isEmpty) return;

    final isDuplicate = _sportTags.any(
      (tag) => tag.toLowerCase() == value.toLowerCase(),
    );
    if (isDuplicate) return;

    setState(() {
      _sportTags.add(value);
      _sportController.clear();
    });
  }

  void _removeSportTag(String tag) {
    setState(() => _sportTags.remove(tag));
  }

  Future<void> _handleComplete() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await _saveOnboardingData();
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isCompleted = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) context.go('/home');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했어요: $e')));
    }
  }

  // 이름은 /profiles/me(PATCH)로, 선호 운동은 태그마다 /exercises(POST)로 저장
  Future<void> _saveOnboardingData() async {
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      throw StateError('로그인 세션이 없습니다.');
    }
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final response = await http.patch(
        Uri.parse(Api.profilesMe),
        headers: headers,
        body: jsonEncode({'nickname': name}),
      );
      if (response.statusCode >= 400) {
        throw Exception('이름 저장 실패 (${response.statusCode})');
      }
    }

    for (final tag in _sportTags) {
      final response = await http.post(
        Uri.parse(Api.exercises),
        headers: headers,
        body: jsonEncode({'name': tag}),
      );
      // 409는 이미 등록된 종목이라는 뜻이라 에러로 취급하지 않고 넘어감
      if (response.statusCode >= 400 && response.statusCode != 409) {
        throw Exception('선호 운동 저장 실패 (${response.statusCode})');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? AppColors.bg9 : AppColors.bg1;
    final hintColor = isDark ? AppColors.bg5 : AppColors.bg4;
    final trackColor = isDark ? AppColors.bg3 : AppColors.bg5;
    final filledColor = isDark ? AppColors.bg9 : AppColors.bg0;
    final borderColor = isDark ? AppColors.bg9 : AppColors.bg0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation<Color>(filledColor),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      _TextStepContent(
                        title: '이름을 알려주세요',
                        hintText: '이름을 입력 해주세요',
                        controller: _nameController,
                        textColor: textColor,
                        hintColor: hintColor,
                        borderColor: borderColor,
                      ),
                      _SportStepContent(
                        controller: _sportController,
                        focusNode: _sportFocusNode,
                        tags: _sportTags,
                        textColor: textColor,
                        hintColor: hintColor,
                        borderColor: borderColor,
                        onAddTag: _addSportTag,
                        onDeleteTag: _removeSportTag,
                      ),
                    ],
                  ),
                ),
                if (!_isLastPage)
                  Center(
                    child: GestureDetector(
                      onTap: _goToNextPage,
                      child: const Text(
                        '건너뛰기',
                        style: TextStyle(fontSize: 14, color: AppColors.bg5),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : (_isLastPage ? _handleComplete : _goToNextPage),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.main,
                      disabledBackgroundColor: AppColors.main,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.bg9,
                              ),
                            ),
                          )
                        : Text(
                            _isLastPage ? '완료하기' : '다음으로',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.bg9,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _stepInputDecoration({
  required String hintText,
  required Color hintColor,
  required Color borderColor,
  Widget? suffixIcon,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(999),
    borderSide: BorderSide(color: borderColor, width: 0.5),
  );
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: hintColor,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: border,
    focusedBorder: border,
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
  );
}

class _TextStepContent extends StatelessWidget {
  const _TextStepContent({
    required this.title,
    required this.hintText,
    required this.controller,
    required this.textColor,
    required this.hintColor,
    required this.borderColor,
  });

  final String title;
  final String hintText;
  final TextEditingController controller;
  final Color textColor;
  final Color hintColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          decoration: _stepInputDecoration(
            hintText: hintText,
            hintColor: hintColor,
            borderColor: borderColor,
          ),
        ),
      ],
    );
  }
}

class _SportStepContent extends StatelessWidget {
  const _SportStepContent({
    required this.controller,
    required this.focusNode,
    required this.tags,
    required this.textColor,
    required this.hintColor,
    required this.borderColor,
    required this.onAddTag,
    required this.onDeleteTag,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> tags;
  final Color textColor;
  final Color hintColor;
  final Color borderColor;
  final VoidCallback onAddTag;
  final ValueChanged<String> onDeleteTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선호하는 운동이 무엇인가요?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                _SportChip(
                  label: tag,
                  borderColor: borderColor,
                  textColor: textColor,
                  onDelete: () => onDeleteTag(tag),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          decoration: _stepInputDecoration(
            hintText: '배드민턴, 농구',
            hintColor: hintColor,
            borderColor: borderColor,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 13),
              child: _AddSportButton(
                borderColor: borderColor,
                iconColor: textColor,
                onTap: onAddTag,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddSportButton extends StatelessWidget {
  const _AddSportButton({
    required this.borderColor,
    required this.iconColor,
    required this.onTap,
  });

  final Color borderColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Icon(Icons.add, size: 16, color: iconColor),
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  const _SportChip({
    required this.label,
    required this.borderColor,
    required this.textColor,
    required this.onDelete,
  });

  final String label;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 10, top: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 18, color: textColor),
          ),
        ],
      ),
    );
  }
}
