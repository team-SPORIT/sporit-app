import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/workout_session.dart';
import '../../shared/app_colors.dart';
import 'widgets/camera_view.dart';

// 운동을 끝내며 마무리 사진을 찍는 화면.
class WorkoutFinishScreen extends StatelessWidget {
  const WorkoutFinishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bg9
            : AppColors.bg1,
        title: const Text('운동 끝내기', style: TextStyle(fontSize: 16)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: CameraView(
        bottomInset: MediaQuery.viewPaddingOf(context).bottom + 24,
        onCaptured: (photo) async {
          await WorkoutSessionController.instance.setEndPhoto(photo.path);
          if (context.mounted) context.push('/record/form');
        },
      ),
    );
  }
}
