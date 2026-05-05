import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeFullscreenPlayerScreen extends StatefulWidget {
  const YoutubeFullscreenPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    this.courseId,
    this.lessonId,
    this.lessonIndex,
    this.watchedPercent,
  });

  final String videoId;
  final String title;
  final String? courseId;
  final String? lessonId;
  final int? lessonIndex;
  final double? watchedPercent;

  @override
  State<YoutubeFullscreenPlayerScreen> createState() =>
      _YoutubeFullscreenPlayerScreenState();
}

class _YoutubeFullscreenPlayerScreenState
    extends State<YoutubeFullscreenPlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseId = widget.courseId?.trim() ?? '';
      if (!mounted || courseId.isEmpty) {
        return;
      }
      context.read<CourseProvider>().saveCoursePlaybackState(
        courseId: courseId,
        currentLessonIndex: widget.lessonIndex ?? 0,
        lessonId: widget.lessonId,
        watchedPercent: widget.watchedPercent ?? 0.35,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.redAccent,
              ),
            ),
            Positioned(
              left: 16,
              top: 10,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
