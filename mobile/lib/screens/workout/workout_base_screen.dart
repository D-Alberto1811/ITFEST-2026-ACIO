import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/quest.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_counter.dart' show ExerciseCounter, ExerciseType, SessionGrade;
import '../../services/pose_service.dart';
import 'workout_camera_overlay.dart';

/// Ecran de bază pentru workout: cameră, detecție pose, counter, overlay, dialog final.
/// Tipul de exercițiu vine din [exerciseType].
class WorkoutBaseScreen extends StatefulWidget {
  final Quest quest;
  final ExerciseType exerciseType;
  final VoidCallback onComplete;

  const WorkoutBaseScreen({
    super.key,
    required this.quest,
    required this.exerciseType,
    required this.onComplete,
  });

  @override
  State<WorkoutBaseScreen> createState() => _WorkoutBaseScreenState();
}

class _WorkoutBaseScreenState extends State<WorkoutBaseScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  PoseService? _poseService;
  late ExerciseCounter _counter;
  int _repCount = 0;
  String _feedback = 'Starting camera...';
  bool _isLoading = true;
  bool _isComplete = false;
  bool _isSwitchingCamera = false;
  Pose? _lastPose;
  int _lastImageWidth = 1;
  int _lastImageHeight = 1;
  int _frameSkipCounter = 0;
  bool _showPoseOverlay = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _counter = ExerciseCounter(
      type: widget.exerciseType,
      target: widget.quest.target,
    );
    _poseService = PoseService();
    _bootstrapCamera();
  }

  static String _overlaySettingKey(int userId) =>
      'exercise_overlay_enabled_user_$userId';

  Future<void> _bootstrapCamera() async {
    final user = await AuthService.instance.getCurrentUser();
    final userId = user?.id;
    if (userId != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_overlaySettingKey(userId)) ?? true;
      if (mounted) setState(() => _showPoseOverlay = enabled);
    }
    if (mounted) await _initCamera();
  }

  List<CameraDescription> _filterCamerasForSwitch(List<CameraDescription> all) {
    final front = all.where((c) => c.lensDirection == CameraLensDirection.front).toList();
    final back = all.where((c) => c.lensDirection == CameraLensDirection.back).toList();
    if (Platform.isIOS) {
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
        final prevCount = _counter.repCount;
        _counter.processPose(pose);
        if (_counter.repCount != prevCount) {
          setState(() => _repCount = _counter.repCount);
          if (_counter.isComplete) {
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
    final grade = _counter.sessionGrade;
    final gradeLabel = _counter.gradeLabel;
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
                  const Text(
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
        return const Color(0xFF22C55E);
      case SessionGrade.B:
        return const Color(0xFF06B6D4);
      case SessionGrade.C:
        return const Color(0xFFFACC15);
      case SessionGrade.D:
        return const Color(0xFFF97316);
      case SessionGrade.E:
        return const Color(0xFFEF4444);
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
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
                    child: WorkoutCameraOverlay(
                      controller: _controller!,
                      lastPose: _lastPose,
                      lastImageWidth: _lastImageWidth.toDouble(),
                      lastImageHeight: _lastImageHeight.toDouble(),
                      sensorOrientation: _controller!.description.sensorOrientation,
                      lensDirection: _controller!.description.lensDirection,
                      showPoseOverlay: _showPoseOverlay,
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
                            'Nota: ${_counter.sessionGrade.name}',
                            style: TextStyle(
                              color: _gradeColor(_counter.sessionGrade),
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
