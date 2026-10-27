import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';

// 운동 기록용 카메라. 미리보기 + 촬영 버튼 + 앞뒤 전환 버튼을 함께 보여준다.
// 시작 사진과 끝내기 사진 양쪽에서 같은 모습으로 쓰인다.
class CameraView extends StatefulWidget {
  const CameraView({
    super.key,
    required this.onCaptured,
    this.isActive = true,
    this.bottomInset = 0,
  });

  // 사진을 찍으면 호출된다. 이 작업이 끝날 때까지 미리보기는 멈춰 있으므로,
  // 확인 팝업처럼 기다리는 동작을 여기서 await하면 찍은 장면이 그대로 멈춘다.
  final Future<void> Function(XFile photo) onCaptured;

  // 화면에 실제로 보일 때만 true. PageView가 옆 페이지를 미리 만들어두기 때문에,
  // 이 값이 false인 동안에는 카메라를 열지 않아야 홈에 들어서자마자 권한을
  // 묻거나 카메라를 점유하는 일이 없다.
  final bool isActive;

  // 촬영 버튼 아래에 비워둘 높이. 홈의 떠 있는 하단 네비게이션처럼 카메라 위에
  // 겹쳐 그려지는 것이 있을 때, 그만큼 자리를 내줘 버튼이 가리지 않게 한다.
  final double bottomInset;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) _setUpCameras();
  }

  @override
  void didUpdateWidget(CameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;

    if (widget.isActive) {
      _setUpCameras();
    } else {
      _controller?.dispose();
      setState(() => _controller = null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    // 앱이 내려갈 때 카메라를 놓아주지 않으면 돌아왔을 때 미리보기가 멈춰 있다.
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      _selectCamera(_cameraIndex);
    }
  }

  Future<void> _setUpCameras() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = '사용할 수 있는 카메라가 없어요');
        return;
      }
      await _selectCamera(0);
    } on CameraException catch (e) {
      // 권한 거부도 여기로 온다.
      setState(() => _error = '카메라를 열 수 없어요 (${e.code})');
    }
  }

  Future<void> _selectCamera(int index) async {
    final previous = _controller;
    _controller = null;
    await previous?.dispose();

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _error = '카메라를 열 수 없어요 (${e.code})');
      return;
    }

    try {
      // 이전에 확대된 상태가 남아 있지 않도록 배율을 최소로 고정한다.
      await controller.setZoomLevel(await controller.getMinZoomLevel());
    } on CameraException catch (_) {
      // 확대를 지원하지 않는 기기면 그대로 둔다.
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _cameraIndex = index;
      _error = null;
    });
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _selectCamera((_cameraIndex + 1) % _cameras.length);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final photo = await controller.takePicture();
      // 찍은 순간이 화면에 멈춰 있도록 미리보기를 세운다.
      await controller.pausePreview();
      await widget.onCaptured(photo);
      if (mounted && _controller == controller) {
        await controller.resumePreview();
      }
    } on CameraException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('사진을 찍지 못했어요 (${e.code})')));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // 가로로 늘려주지 않으면 미리보기는 비율대로 줄어들어 좌우에 여백이 생기고,
      // 버튼을 담은 Stack도 촬영 버튼 너비만큼만 넓어져서 전환 버튼이 그 뒤에
      // 겹쳐버린다.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Expanded(child: _buildPreview()),
        SizedBox(
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ShutterButton(onTap: _capture, isBusy: _isCapturing),
              Positioned(
                right: 28,
                child: _SwitchCameraButton(
                  onTap: _cameras.length < 2 ? null : _switchCamera,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: widget.bottomInset),
      ],
    );
  }

  Widget _buildPreview() {
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.bg5),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // 미리보기 비율을 유지한 채 영역을 꽉 채운다(넘치는 부분은 잘라냄).
    return GestureDetector(
      // 손가락을 오므리거나 벌리는 동작을 여기서 받아 아무것도 하지 않는 것으로
      // 처리한다. 확대/축소가 생기지 않도록 막아두는 것.
      onScaleStart: (_) {},
      onScaleUpdate: (_) {},
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1,
            height: controller.value.previewSize?.width ?? 1,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onTap, required this.isBusy});

  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 어두운 배경에서는 흰 버튼, 밝은 배경에서는 회색 버튼이어야 보인다.
    final color = isDark ? AppColors.bg9 : AppColors.bg3;

    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBusy ? AppColors.bg5 : color,
          ),
        ),
      ),
    );
  }
}

class _SwitchCameraButton extends StatelessWidget {
  const _SwitchCameraButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.bg9 : AppColors.bg5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(Icons.cached, size: 24, color: color),
      ),
    );
  }
}
