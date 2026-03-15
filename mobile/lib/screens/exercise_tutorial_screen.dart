import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/quest.dart';
import 'workout_screen.dart';

class ExerciseTutorialScreen extends StatefulWidget {
  final Quest quest;
  final VoidCallback onComplete;

  const ExerciseTutorialScreen({
    super.key,
    required this.quest,
    required this.onComplete,
  });

  @override
  State<ExerciseTutorialScreen> createState() => _ExerciseTutorialScreenState();
}

class _ExerciseTutorialScreenState extends State<ExerciseTutorialScreen> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;

  String get _videoAssetPath {
    switch (widget.quest.type) {
      case 'pushup':
        return 'assets/videos/tutorials/Push-ups.mp4';
      case 'squat':
        return 'assets/videos/tutorials/Squats.mp4';
      case 'jumping_jack':
        return 'assets/videos/tutorials/Jumping.mp4';
      default:
        return 'assets/videos/tutorials/Push-ups.mp4';
    }
  }

  String get _tutorialTitle {
    switch (widget.quest.type) {
      case 'pushup':
        return 'Push-up Tutorial';
      case 'squat':
        return 'Squat Tutorial';
      case 'jumping_jack':
        return 'Jumping Jack Tutorial';
      default:
        return 'Exercise Tutorial';
    }
  }

  String get _tutorialHint {
    switch (widget.quest.type) {
      case 'pushup':
        return 'Keep your body straight, lower with control, then push back up.';
      case 'squat':
        return 'Keep your back straight, bend your knees, then rise back up.';
      case 'jumping_jack':
        return 'Jump with feet apart and hands overhead, then return to start.';
      default:
        return 'Watch the short demo before starting the exercise.';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.asset(_videoAssetPath);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _startExercise() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          quest: widget.quest,
          onComplete: widget.onComplete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          _tutorialTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.quest.icon,
                      style: const TextStyle(fontSize: 34),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.quest.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _tutorialHint,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _isInitializing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF06B6D4),
                            ),
                          )
                        : _hasError || controller == null
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Tutorial video could not be loaded.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  Center(
                                    child: AspectRatio(
                                      aspectRatio: controller.value.aspectRatio,
                                      child: VideoPlayer(controller),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (controller.value.isPlaying) {
                                          controller.pause();
                                        } else {
                                          controller.play();
                                        }
                                        setState(() {});
                                      },
                                      child: Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: const Color(0xCC0F172A),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                        child: Icon(
                                          controller.value.isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _startExercise,
                    style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: const Color(0xFF0F172A),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                    ),
                    ),
                    child: const Text(
                    'Start exercise',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                    ),
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}