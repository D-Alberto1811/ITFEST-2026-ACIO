import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/quest.dart';
import '../services/pose_service.dart';
import '../services/exercise_counter.dart';

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

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('No cameras found');
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('🏆 Quest Complete!', style: TextStyle(color: Colors.white)),
        content: Text(
          '+${widget.quest.rewardXp} XP  +${widget.quest.rewardGems} 💎',
          style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 18),
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

  const _CameraPreviewWithOverlay({
    required this.controller,
    required this.lastPose,
    required this.lastImageWidth,
    required this.lastImageHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Pe iOS uneori aspect ratio e raportat invers pentru portrait
    final ar = controller.value.aspectRatio;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final displayAr = (Platform.isIOS && isPortrait && ar > 1) ? 1 / ar : ar;
    return AspectRatio(
      aspectRatio: displayAr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          if (lastPose != null)
            CustomPaint(
              painter: _PoseOverlayPainter(
                pose: lastPose!,
                imageWidth: lastImageWidth,
                imageHeight: lastImageHeight,
              ),
            ),
        ],
      ),
    );
  }
}

class _PoseOverlayPainter extends CustomPainter {
  final Pose pose;
  final double imageWidth;
  final double imageHeight;

  _PoseOverlayPainter({
    required this.pose,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

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
      ..color = const Color(0xFF06B6D4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final (a, b) in connections) {
      final p1 = pose.landmarks[a];
      final p2 = pose.landmarks[b];
      if (p1 != null && p2 != null && p1.likelihood > 0.5 && p2.likelihood > 0.5) {
        canvas.drawLine(
          Offset(p1.x * scaleX, p1.y * scaleY),
          Offset(p2.x * scaleX, p2.y * scaleY),
          linePaint,
        );
      }
    }

    // Desenează punctele (joint-uri)
    final pointPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    for (final landmark in pose.landmarks.values) {
      if (landmark.likelihood > 0.5) {
        canvas.drawCircle(
          Offset(landmark.x * scaleX, landmark.y * scaleY),
          6,
          pointPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PoseOverlayPainter oldDelegate) => true;
}
