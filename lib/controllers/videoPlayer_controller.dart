import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerControllerProvider extends ChangeNotifier {
  // Video Controller
  late VideoPlayerController _controller;
  VideoPlayerController get controller => _controller;

  // Pan Gesture Tracking
  Offset? _startPoint;
  Offset? _endPoint;

  // Timers
  Timer? _hideControlsTimer;
  Timer? _screenshotTimer;

  // Video State
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isMuted = false;
  bool _isPlaying = false;
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isBuffering = false;
  bool _isDraggingProgressBar = false;
  bool _isRectangleDrawn = false;
  bool _isDisposed = false;

  // Playback
  double _playbackSpeed = 1.0;

  // Text Recognition and Translation
  final textRecognizer = TextRecognizer();
  late OnDeviceTranslator onDeviceTranslator;
  String _extractedText = '';
  String _translatedText = '';
  bool _showTextDisplay = false;
  Offset _textDisplayPosition = Offset.zero;

  // Getters for video state
  bool get showControls => _showControls;
  bool get isFullscreen => _isFullscreen;
  bool get isMuted => _isMuted;
  bool get isPlaying => _isPlaying;
  Duration get videoDuration => _videoDuration;
  Duration get currentPosition => _currentPosition;
  bool get isBuffering => _isBuffering;
  bool get isDraggingProgressBar => _isDraggingProgressBar;
  double get playbackSpeed => _playbackSpeed;
  Timer? get screenshotTimer => _screenshotTimer;
  // Getters for text-related properties
  String get extractedText => _extractedText;
  String get translatedText => _translatedText;
  bool get showTextDisplay => _showTextDisplay;
  Offset get textDisplayPosition => _textDisplayPosition;
  // Pan Gesture Tracking
  Offset? get startPoint => _startPoint;
  Offset? get endPoint => _endPoint;
  bool get isDisposed => _isDisposed;

  // RepaintBoundary Key
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  GlobalKey get repaintBoundaryKey => _repaintBoundaryKey;

  VideoPlayerControllerProvider() {
    _controller = VideoPlayerController.asset('');
  }

  // Added method to completely reset the controller state
  Future<void> resetController() async {
    try {
      // Cancel any ongoing timers
      _hideControlsTimer?.cancel();
      _screenshotTimer?.cancel();
      // Pause and dispose of existing controller if it exists
        await _controller?.pause();
        await _controller?.dispose();
      // Reset all state variables
      _isDisposed = false;
      _showControls = true;
      _isFullscreen = false;
      _isMuted = false;
      _isPlaying = false;
      _videoDuration = Duration.zero;
      _currentPosition = Duration.zero;
      _isBuffering = false;
      _isDraggingProgressBar = false;
      // Reset rectangle-related state as well
      _startPoint = null;
      _endPoint = null;
      _isRectangleDrawn = false;
      // Reset text-related states
      resetTranslationState();
      // Close resources
      await textRecognizer.close();
      await onDeviceTranslator.close();
      notifyListeners();
    } catch (e) {
      log('Error during controller reset: $e');
    }
  }

  Future<void> initializeController(
      String? getSelectedVideoPath, OnDeviceTranslator onDevice) async {
    await resetController();
    if (getSelectedVideoPath == null || getSelectedVideoPath.isEmpty) {
      log('Video path is null or empty, cannot initialize controller');
      return;
    }
    final videoFile = File(getSelectedVideoPath);
    if (!await videoFile.exists()) {
      log('Video file does not exist: $getSelectedVideoPath');
      return;
    }
    try {
      _controller = VideoPlayerController.file(videoFile);
      await _controller!.initialize();
      _videoDuration = _controller!.value.duration;
      _controller!.addListener(
        () {
          if (_controller == null) return;
          _currentPosition = _controller!.value.position;
          if (_currentPosition >= _videoDuration) {
            _isPlaying = false;
            _controller!.pause();
          }
          notifyListeners();
        },
      );
      await _controller!.play();
      _showControls = false;
      resetHideControlsTimer();
      _isPlaying = true;
      _isBuffering = false;
      onDeviceTranslator = onDevice;
      log('Video Controller Initialized Successfully');
      notifyListeners();
    } catch (error) {
      log('Error initializing video player: $error');
      _isBuffering = false;
      notifyListeners();
    }
  }

  Future<void> _captureScreenshot() async {
    if (isDisposed) return;
    if (_startPoint == null || _endPoint == null) return;
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final fullImage = await boundary.toImage(pixelRatio: 1.0);
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
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.clipRect(Rect.fromLTWH(0, 0, rect.width, rect.height));
      canvas.drawImage(
        fullImage,
        Offset(-rect.left, -rect.top),
        Paint(),
      );
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        rect.width.toInt(),
        rect.height.toInt(),
      );
      final byteData =
          await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final directory = await getTemporaryDirectory();
      if (directory == null) return;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/screenshot_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      // Extract text
      final inputImage = InputImage.fromFilePath(filePath);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      // Translate text
      if (recognizedText.text.isNotEmpty) {
        final translatedResult =
            await onDeviceTranslator.translateText(recognizedText.text);
        _extractedText = recognizedText.text;
        _translatedText = translatedResult;
        _showTextDisplay = true;
        _textDisplayPosition = Offset(
          _endPoint!.dx + 10,
          _startPoint!.dy,
        );
        notifyListeners();
      }
      log('Extracted Text: ${recognizedText.text}');
      for (TextBlock block in recognizedText.blocks) {
        log('Block Text: ${block.text}');
      }
      fullImage.dispose();
      croppedImage.dispose();
      await textRecognizer.close();
      notifyListeners();
    } catch (e) {
      log('Error capturing screenshot: $e');
      log('Error in capture and translation: $e');
    }
  }

  void initializeTranslator(String sourceLanguage, String targetLanguage) {
    if (isDisposed) return;
    try {
      log('Initializing translator with source: $sourceLanguage, target: $targetLanguage');
      final source = TranslateLanguage.values.firstWhere(
        (element) => element.bcpCode == sourceLanguage,
        orElse: () {
          log('Invalid source language code: $sourceLanguage');
          throw Exception('Source language not supported');
        },
      );
      final target = TranslateLanguage.values.firstWhere(
        (element) => element.bcpCode == targetLanguage,
        orElse: () {
          log('Invalid target language code: $targetLanguage');
          throw Exception('Target language not supported');
        },
      );
      onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
      log('Translator initialized successfully.');
    } catch (e) {
      log('Error initializing translator: $e');
    }
  }

  // Play/Pause toggle
  void togglePlayPause() {
    if (isDisposed) return;
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _isPlaying = _controller.value.isPlaying;
    _showControls = true;
    resetHideControlsTimer();
    notifyListeners();
  }

  // Fullscreen toggle
  void toggleFullscreen() {
    if (isDisposed) return;
    _isFullscreen = !_isFullscreen;
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
    notifyListeners();
  }

  // Mute toggle
  void toggleMute() {
    if (isDisposed) return;
    _isMuted = !_isMuted;
    _controller.setVolume(_isMuted ? 0 : 1);
    resetHideControlsTimer();
    notifyListeners();
  }

  // Reset hide controls timer
  void resetHideControlsTimer() {
    if (isDisposed) return;
    _showControls = true;
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(
      const Duration(seconds: 3),
      () {
        if (_controller.value.isPlaying) {
          _showControls = false;
          notifyListeners();
        }
      },
    );
  }

  void changePlaybackSpeed() {
    if (_controller == null || !_controller.value.isInitialized) return;
    final speeds = [0.5, 1.0, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    _playbackSpeed = speeds[(currentIndex + 1) % speeds.length];
    _controller.setPlaybackSpeed(_playbackSpeed);
    notifyListeners();
  }


  void onPanStart(DragStartDetails details) {
    if (isDisposed) return;
    _startPoint = details.localPosition;
    _endPoint = _startPoint;
    _isRectangleDrawn = false;
    notifyListeners();
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (isDisposed) return;
    _endPoint = details.localPosition;
    notifyListeners();
  }

  void onPanEnd(DragEndDetails details) {
    if (isDisposed) return;
    if (_startPoint != null && _endPoint != null && !_isRectangleDrawn) {
      _screenshotTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          _captureScreenshot();
        },
      );
      _isRectangleDrawn = true;
      notifyListeners();
    }
  }

  void onTap() {
    _showControls = !_showControls;
    notifyListeners();
    if (_showControls) {
      resetHideControlsTimer();
      notifyListeners();
    }
  }

  void onDoubleTap() {
    if (isDisposed) return;
    if (_isRectangleDrawn) {
      _isRectangleDrawn = false;
      _screenshotTimer?.cancel();
      _startPoint = null;
      _endPoint = null;
      notifyListeners();
    }
  }




  String formatDuration(Duration duration) {
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

  void seekRelative(Duration duration) {
    if (isDisposed || _controller == null) return;
    _currentPosition = _controller!.value.position;
    final newPosition = _currentPosition + duration;
    if (newPosition < Duration.zero) {
      _controller!.seekTo(Duration.zero);
      _currentPosition = Duration.zero;
    } else if (newPosition > _videoDuration) {
      _controller!.seekTo(_videoDuration);
      _currentPosition = _videoDuration;
    } else {
      _controller!.seekTo(newPosition);
      _currentPosition = newPosition;
    }

    notifyListeners();
  }

  void resetTranslationState() {
    _showTextDisplay = false;
    _extractedText = '';
    _translatedText = '';
    _textDisplayPosition = Offset.zero;
    notifyListeners();
  }

  Future<void> disposing() async {
    await _controller.pause();
    await _controller.dispose();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _controller.pause();
    resetTranslationState();
    _controller.seekTo(Duration.zero);
    // Clean up resources
    _hideControlsTimer?.cancel();
    _screenshotTimer?.cancel();
    textRecognizer.close();
    onDeviceTranslator.close();
    _controller.dispose();
    // Reset properties
    _videoDuration = Duration.zero;
    _currentPosition = Duration.zero;
    _isBuffering = false;
    _isDraggingProgressBar = false;
    _isRectangleDrawn = false;
    _showTextDisplay = false;
    _textDisplayPosition = Offset.zero;
    _showControls = false;
    _translatedText = '';
    _extractedText = '';
    _isPlaying = false;
    _isFullscreen = false;
    _isMuted = false;
    notifyListeners();
    super.dispose();
  }
}
