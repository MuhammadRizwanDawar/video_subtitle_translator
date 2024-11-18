import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String? thumbnailPath;

  const VideoPlayerScreen({
    Key? key,
    required this.videoPath,
    this.thumbnailPath,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool isFullscreen = false;
  bool isMuted = false;
  bool isBuffering = false;
  double playbackSpeed = 1.0;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Duration _currentPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  bool _isDraggingProgressBar = false;

  // For drawing rectangle
  Offset? _startPoint;
  Offset? _endPoint;

  // RepaintBoundary Key
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Timer to capture screenshots at regular intervals
  Timer? _screenshotTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _startScreenshotTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer?.cancel();
    _screenshotTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..addListener(_videoListener)
      ..setLooping(true);

    try {
      await _controller.initialize();
      _videoDuration = _controller.value.duration;
      setState(() {});
    } catch (e) {
      print('Error initializing video player: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load video: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _videoListener() {
    if (!mounted) return;

    final position = _controller.value.position;
    if (position != _currentPosition && !_isDraggingProgressBar) {
      setState(() => _currentPosition = position);
    }

    final isBuffering = _controller.value.isBuffering;
    if (isBuffering != this.isBuffering) {
      setState(() => this.isBuffering = isBuffering);
    }

    final isPlaying = _controller.value.isPlaying;
    if (isPlaying != _isPlaying) {
      setState(() => _isPlaying = isPlaying);
    }
  }

  Future<void> _captureScreenshot() async {
    if (_startPoint == null || _endPoint == null) return;

    try {
      // Get the boundary
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture the full image
      final fullImage = await boundary.toImage(pixelRatio: 1.0); // or 2.0


      // Create a rect from the points
      final rect = Rect.fromPoints(
        Offset(
          _startPoint!.dx.clamp(0, fullImage.width.toDouble()),
          _startPoint!.dy.clamp(0, fullImage.height.toDouble()),
        ),
        Offset(
          _endPoint!.dx.clamp(0, fullImage.width.toDouble()),
          _endPoint!.dy.clamp(0, fullImage.height.toDouble()),
        ),
      );

      // Create a picture recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw only the selected portion
      canvas.clipRect(Rect.fromLTWH(0, 0, rect.width, rect.height));
      canvas.drawImage(
        fullImage,
        Offset(-rect.left, -rect.top),
        Paint(),
      );

      // Convert to image
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        rect.width.toInt(),
        rect.height.toInt(),
      );

      // Convert to bytes
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // Save the file
      final directory = await getExternalStorageDirectory();
      if (directory == null) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/screenshot_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      log('Screenshot saved to: $filePath');

      // Clean up
      fullImage.dispose();
      croppedImage.dispose();
    } catch (e) {
      log('Error capturing screenshot: $e');
    }
  }

  void _startScreenshotTimer() {
    _screenshotTimer?.cancel();
    _screenshotTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && _startPoint != null && _endPoint != null) {
        _captureScreenshot();
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _resetHideControlsTimer();
    });
  }

  void _toggleFullscreen() {
    setState(() {
      isFullscreen = !isFullscreen;
      if (isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      }
    });
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
      _controller.setVolume(isMuted ? 0 : 1);
      _resetHideControlsTimer();
    });
  }

  void _resetHideControlsTimer() {
    _showControls = true;
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _seekRelative(Duration duration) {
    final newPosition = _currentPosition + duration;
    if (newPosition < Duration.zero) {
      _controller.seekTo(Duration.zero);
    } else if (newPosition > _videoDuration) {
      _controller.seekTo(_videoDuration);
    } else {
      _controller.seekTo(newPosition);
    }
    _resetHideControlsTimer();
  }

  void _changePlaybackSpeed() {
    setState(() {
      final speeds = [0.5, 1.0, 1.5, 2.0];
      final currentIndex = speeds.indexOf(playbackSpeed);
      playbackSpeed = speeds[(currentIndex + 1) % speeds.length];
      _controller.setPlaybackSpeed(playbackSpeed);
      _resetHideControlsTimer();
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  Widget _buildProgressBar() {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: Colors.red,
        inactiveTrackColor: Colors.grey[400],
        thumbColor: Colors.red,
        overlayColor: Colors.red.withOpacity(0.3),
      ),
      child: Slider(
        value: _currentPosition.inMilliseconds.toDouble(),
        min: 0,
        max: _videoDuration.inMilliseconds.toDouble(),
        onChanged: (value) {
          setState(() {
            _currentPosition = Duration(milliseconds: value.toInt());
          });
        },
        onChangeStart: (_) {
          _isDraggingProgressBar = true;
          _controller.pause();
        },
        onChangeEnd: (value) {
          _isDraggingProgressBar = false;
          _controller.seekTo(Duration(milliseconds: value.toInt()));
          if (_isPlaying) _controller.play();
        },
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _endPoint = details.localPosition;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _startPoint = details.localPosition;
      _endPoint = _startPoint;
    });
  }
  void _onPanEnd(DragEndDetails details) {
    if (_startPoint != null && _endPoint != null) {
      // Capture screenshot after the rectangle is drawn
      _captureScreenshot();
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: isFullscreen
          ? null
          : AppBar(
        backgroundColor: Colors.black,
        title: const Text('Video Player'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Stack(
                    children: [
                      VideoPlayer(_controller),
                      GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: RectanglePainter(
                            startPoint: _startPoint,
                            endPoint: _endPoint,
                          ),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isBuffering)
                  const Center(child: CircularProgressIndicator()),

                if (_showControls)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                color: Colors.white,
                              ),
                              onPressed: _toggleFullscreen,
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildProgressBar(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  '${_formatDuration(_currentPosition)} / ${_formatDuration(_videoDuration)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isMuted
                                            ? Icons.volume_off
                                            : Icons.volume_up,
                                        color: Colors.white,
                                      ),
                                      onPressed: _toggleMute,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.replay_10,
                                        color: Colors.white,
                                      ),
                                      onPressed: () =>
                                          _seekRelative(const Duration(seconds: -10)),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                      onPressed: _togglePlayPause,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.forward_10,
                                        color: Colors.white,
                                      ),
                                      onPressed: () =>
                                          _seekRelative(const Duration(seconds: 10)),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.speed,
                                        color: Colors.white,
                                      ),
                                      onPressed: _changePlaybackSpeed,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RectanglePainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? endPoint;

  RectanglePainter({this.startPoint, this.endPoint});

  @override
  void paint(Canvas canvas, Size size) {
    if (startPoint == null || endPoint == null) return;

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromPoints(startPoint!, endPoint!);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

