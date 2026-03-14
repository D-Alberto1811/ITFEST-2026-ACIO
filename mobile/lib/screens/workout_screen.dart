import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/quest.dart';
import '../services/pose_service.dart';
import '../services/exercise_counter.dart' show ExerciseCounter, ExerciseType, SessionGrade;

class WorkoutScreen extends StatefulWidget {
  final Quest quest;
  final VoidCallback onComplete;

  const WorkoutScreen({super.key, required this.quest, required this.onComplete});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  PoseService? _poseService;
  ExerciseCounter? _counter;
  int _repCount = 0;
  String _feedback = 'Starting camera...';
  bool _isLoading = true;
  bool _isComplete = false;
  bool _isSwitchingCamera = false;
  Pose? _lastPose;
  int _lastImageWidth = 1;
  int _lastImageHeight = 1;
  int _frameSkipCounter = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _poseService = PoseService();
    _counter = ExerciseCounter(
      type: _questTypeFromString(widget.quest.type),
      target: widget.quest.target,
    );
  }

  ExerciseType _questTypeFromString(String type) {
    switch (type) {
      case 'pushup': return ExerciseType.pushup;
      case 'squat': return ExerciseType.squat;
      case 'jumping_jack': return ExerciseType.jumpingJack;
      default: return ExerciseType.pushup;
    }
  }

  /// Filtrează camerele: pe iOS doar selfie + back wide (1x). Pe Android: selfie + primul back.
  List<CameraDescription> _filterCamerasForSwitch(List<CameraDescription> all) {
    final front = all.where((c) => c.lensDirection == CameraLensDirection.front).toList();
    final back = all.where((c) => c.lensDirection == CameraLensDirection.back).toList();
    if (Platform.isIOS) {
      // Pe iOS preferă back wide (1x), nu ultra-wide/macro/telephoto
      final backWide = back.where((c) => c.lensType == CameraLensType.wide).toList();
      final backMain = backWide.isNotEmpty ? backWide : back;
      return [...front.take(1), ...backMain.take(1)];
    }
    return [...front.take(1), ...back.take(1)];
  }

  Future<void> _initCamera() async {
    try {
      final allCameras = await availableCameras();
      if (allCameras.isEmpty) throw Exception('No cameras found');
      // Pe iOS: doar selfie (front) + camera 1x (back wide). Pe Android: front + primul back.
      _cameras = _filterCamerasForSwitch(allCameras);
      if (_cameras.isEmpty) _cameras = allCameras;
      _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_cameraIndex < 0) _cameraIndex = 0;
      await _createController();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _feedback = 'Camera error: $e';
      });
    }
  }

  Future<void> _createController() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );
    await _controller!.initialize();
    if (!mounted) return;
    // Forțează zoom 1x (evită macro pe iOS)
    try {
      await _controller!.setZoomLevel(1.0);
    } catch (_) {}
    setState(() {
      _isLoading = false;
      _feedback = 'Position yourself in frame';
    });
    _startPoseDetection();
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isSwitchingCamera || _isComplete) return;
    setState(() {
      _isSwitchingCamera = true;
      _isLoading = true;
    });
    try {
      _controller?.stopImageStream();
      await _controller?.dispose();
      _controller = null;
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      await _createController();
    } catch (e) {
      if (mounted) setState(() {
        _feedback = 'Switch failed: $e';
        _isLoading = false;
      });
    } finally {
      if (mounted) setState(() => _isSwitchingCamera = false);
    }
  }

  void _startPoseDetection() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      if (_isComplete || !mounted) return;

      // Procesează 1 din 3 frame-uri pentru optimizare (reduce încălzirea)
      _frameSkipCounter++;
      if (_frameSkipCounter % 3 != 0) return;

      final rotation = _getRotation();
      final poses = await _poseService!.processCameraImage(image, rotation);

      if (!mounted) return;

      if (poses.isNotEmpty) {
        final pose = poses.first;
        setState(() {
          _lastPose = pose;
          _lastImageWidth = image.width;
          _lastImageHeight = image.height;
        });
        final prevCount = _counter!.repCount;
        _counter!.processPose(pose);
        if (_counter!.repCount != prevCount) {
          setState(() => _repCount = _counter!.repCount);
          if (_counter!.isComplete) {
            _isComplete = true;
            _controller?.stopImageStream();
            if (mounted) _showCompleteDialog();
          }
        }
      }
    });
  }

  InputImageRotation _getRotation() {
    final sensorOrientation = _controller!.description.sensorOrientation;
    if (Platform.isAndroid) {
      switch (sensorOrientation) {
        case 90: return InputImageRotation.rotation90deg;
        case 180: return InputImageRotation.rotation180deg;
        case 270: return InputImageRotation.rotation270deg;
        default: return InputImageRotation.rotation0deg;
      }
    }
    return InputImageRotation.rotation0deg;
  }

  void _showCompleteDialog() {
    final grade = _counter!.sessionGrade;
    final gradeLabel = _counter!.gradeLabel;
    final gradeColor = _gradeColor(grade);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('🏆 Quest Complete!', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: gradeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gradeColor),
              ),
              child: Row(
                children: [
                  Text(
                    'Nota: ',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    gradeLabel,
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '+${widget.quest.rewardXp} XP  +${widget.quest.rewardGems} 💎',
              style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onComplete();
              Navigator.pop(context);
            },
            child: const Text('Claim', style: TextStyle(color: Color(0xFF06B6D4))),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(SessionGrade grade) {
    switch (grade) {
      case SessionGrade.A:
        return const Color(0xFF22C55E); // green
      case SessionGrade.B:
        return const Color(0xFF06B6D4); // cyan
      case SessionGrade.C:
        return const Color(0xFFFACC15); // yellow
      case SessionGrade.D:
        return const Color(0xFFF97316); // orange
      case SessionGrade.E:
        return const Color(0xFFEF4444); // red
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _poseService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.quest.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  Center(
                    child: _CameraPreviewWithOverlay(
                      controller: _controller!,
                      lastPose: _lastPose,
                      lastImageWidth: _lastImageWidth.toDouble(),
                      lastImageHeight: _lastImageHeight.toDouble(),
                      sensorOrientation: _controller!.description.sensorOrientation,
                      lensDirection: _controller!.description.lensDirection,
                    ),
                  ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reps', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          '$_repCount / ${widget.quest.target}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_repCount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Nota: ${_counter!.sessionGrade.name}',
                            style: TextStyle(
                              color: _gradeColor(_counter!.sessionGrade),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _feedback,
                        style: const TextStyle(color: Color(0xFFFACC15), fontSize: 16),
                      ),
                    ),
                  ),
                ),
                if (_cameras.length > 1)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: _isSwitchingCamera ? null : _switchCamera,
                      icon: Icon(
                        Icons.cameraswitch,
                        color: _isSwitchingCamera ? Colors.grey : Colors.white,
                        size: 32,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CameraPreviewWithOverlay extends StatelessWidget {
  final CameraController controller;
  final Pose? lastPose;
  final double lastImageWidth;
  final double lastImageHeight;
  final int sensorOrientation;
  final CameraLensDirection lensDirection;

  const _CameraPreviewWithOverlay({
    required this.controller,
    required this.lastPose,
    required this.lastImageWidth,
    required this.lastImageHeight,
    required this.sensorOrientation,
    required this.lensDirection,
  });

  @override
  Widget build(BuildContext context) {
    // Pe iOS/Android uneori aspect ratio e raportat invers pentru portrait
    final ar = controller.value.aspectRatio;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final displayAr = (isPortrait && ar > 1) ? 1 / ar : ar;
    return AspectRatio(
      aspectRatio: displayAr,
      child: CameraPreview(
        controller,
        child: lastPose != null
            ? IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _PoseOverlayPainter(
                        pose: lastPose!,
                        imageWidth: lastImageWidth,
                        imageHeight: lastImageHeight,
                        sensorOrientation: sensorOrientation,
                        lensDirection: lensDirection,
                        screenSize: Size(constraints.maxWidth, constraints.maxHeight),
                        previewAspectRatio: ar,
                      ),
                    );
                  },
                ),
              )
            : null,
      ),
    );
  }
}

class _PoseOverlayPainter extends CustomPainter {
  final Pose pose;
  final double imageWidth;
  final double imageHeight;
  final int sensorOrientation;
  final CameraLensDirection lensDirection;
  final Size? screenSize;
  final double? previewAspectRatio;

  _PoseOverlayPainter({
    required this.pose,
    required this.imageWidth,
    required this.imageHeight,
    this.sensorOrientation = 0,
    this.lensDirection = CameraLensDirection.back,
    this.screenSize,
    this.previewAspectRatio,
  });

  Offset _translatePoint(double x, double y, Size canvasSize) {
    if (Platform.isIOS) {
      return _translatePointIOS(x, y, canvasSize);
    }
    return _translatePointAndroid(x, y, canvasSize);
  }

  Offset _translatePointIOS(double x, double y, Size canvasSize) {
    final imageSize = Size(imageWidth, imageHeight);
    final rot = _rotation;
    final screenX = _translateX(x, canvasSize, imageSize, rot, true);
    final screenY = _translateY(y, canvasSize, imageSize, rot, true);
    return Offset(screenX, screenY);
  }

  InputImageRotation get _rotation {
    switch (sensorOrientation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  /// Pe Android: transformare coordonate. canvasSize = full screen când overlay e Positioned.fill.
  Offset _translatePointAndroid(double x, double y, Size canvasSize) {
    final rect = _getPreviewRect(canvasSize);
    final w = imageWidth;
    final h = imageHeight;
    double localX, localY;
    switch (sensorOrientation) {
      case 90:
        localX = y * rect.width / h;
        localY = (w - x) * rect.height / w;
        break;
      case 270:
        localX = (h - y) * rect.width / h;
        localY = x * rect.height / w;
        break;
      case 180:
        localX = (w - x) * rect.width / w;
        localY = (h - y) * rect.height / h;
        break;
      default:
        localX = x * rect.width / w;
        localY = y * rect.height / h;
    }
    if (lensDirection == CameraLensDirection.front && (sensorOrientation == 0 || sensorOrientation == 180)) {
      localX = rect.width - localX;
    }
    return Offset(rect.left + localX, rect.top + localY);
  }

  Rect _getPreviewRect(Size screenSize) {
    if (previewAspectRatio == null) return Offset.zero & screenSize;
    final ar = previewAspectRatio!;
    final isPortrait = screenSize.height > screenSize.width;
    final displayAr = (isPortrait && ar > 1) ? 1 / ar : ar;
    double w = screenSize.width, h = screenSize.height;
    if (w / h > displayAr) {
      w = h * displayAr;
    } else {
      h = w / displayAr;
    }
    final left = (screenSize.width - w) / 2;
    final top = (screenSize.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  double _translateX(double x, Size canvasSize, Size imageSize, InputImageRotation rot, bool isIOS) {
    switch (rot) {
      case InputImageRotation.rotation90deg:
        return x * canvasSize.width / (isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation270deg:
        return canvasSize.width - x * canvasSize.width / (isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return lensDirection == CameraLensDirection.back
            ? x * canvasSize.width / imageSize.width
            : canvasSize.width - x * canvasSize.width / imageSize.width;
    }
  }

  double _translateY(double y, Size canvasSize, Size imageSize, InputImageRotation rot, bool isIOS) {
    switch (rot) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * canvasSize.height / (isIOS ? imageSize.height : imageSize.width);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * canvasSize.height / imageSize.height;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final canvasSize = Size(size.width, size.height);
    final minLikelihood = Platform.isAndroid ? 0.2 : 0.5;

    // Desenează linii între joint-uri conectate
    final connections = [
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
      (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
      (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
      (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
      (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
      (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
      (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
      (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
      (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
      (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
    ];

    final linePaint = Paint()
      ..color = Platform.isAndroid ? const Color(0xFF00FFFF) : const Color(0xFF06B6D4)
      ..strokeWidth = Platform.isAndroid ? 5 : 3
      ..style = PaintingStyle.stroke;

    for (final (a, b) in connections) {
      final p1 = pose.landmarks[a];
      final p2 = pose.landmarks[b];
      if (p1 != null && p2 != null && p1.likelihood > minLikelihood && p2.likelihood > minLikelihood) {
        final pt1 = _translatePoint(p1.x, p1.y, canvasSize);
        final pt2 = _translatePoint(p2.x, p2.y, canvasSize);
        canvas.drawLine(pt1, pt2, linePaint);
      }
    }

    // Desenează punctele (joint-uri)
    final pointPaint = Paint()
      ..color = Platform.isAndroid ? const Color(0xFFFFFF00) : const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    final pointRadius = Platform.isAndroid ? 12.0 : 6.0;
    for (final landmark in pose.landmarks.values) {
      if (landmark.likelihood > minLikelihood) {
        final pt = _translatePoint(landmark.x, landmark.y, canvasSize);
        canvas.drawCircle(pt, pointRadius, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PoseOverlayPainter oldDelegate) => true;
}
