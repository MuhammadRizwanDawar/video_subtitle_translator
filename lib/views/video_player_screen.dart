import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_subtitle_translator/controllers/video_controller.dart';
import 'package:video_subtitle_translator/utlis/drawrec_custompaint.dart';
import '../controllers/videoPlayer_controller.dart';
import '../widgets/videocontrols_widgets.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerControllerProvider controller;
  late LanguageChooseController languageChooseController;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      languageChooseController =
          Provider.of<LanguageChooseController>(context, listen: false);
      controller =
          Provider.of<VideoPlayerControllerProvider>(context, listen: false);
      String? getSelectedVideoPath = languageChooseController
          .getSelectedVideoPath();
      if (getSelectedVideoPath != null && getSelectedVideoPath.isNotEmpty) {
        controller.initializeTranslator(
            languageChooseController.sourceLanguage,
            languageChooseController.targetLanguage
        );
        controller.initializeController(
            getSelectedVideoPath, controller.onDeviceTranslator);
      } else {
        log("No video path selected.");
      }
    });
  }


  @override
  void dispose() {
    controller.disposing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the controller and get the selected video path
    final controller = Provider.of<LanguageChooseController>(context);
    final videoPath = controller.getSelectedVideoPath();

    if (videoPath == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("No video selected")),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Consumer<VideoPlayerControllerProvider>(
            builder: (context, controller, _) {
              if (!controller.controller!.value.isInitialized) {
                return const CircularProgressIndicator();
              }
              return AspectRatio(
                aspectRatio: controller.controller.value.aspectRatio,
                child: RepaintBoundary(
                  key: controller.repaintBoundaryKey,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Consumer<VideoPlayerControllerProvider>(
                          builder: (context, controller, _) {
                            return VideoPlayer(controller.controller);
                          }),
                      Consumer<VideoPlayerControllerProvider>(
                        builder: (context, controller, _) {
                          return GestureDetector(
                            onTap: controller.onTap,
                            onDoubleTap: controller.onDoubleTap,
                            onPanStart: controller.onPanStart,
                            onPanUpdate: controller.onPanUpdate,
                            onPanEnd: controller.onPanEnd,
                            child: CustomPaint(
                              painter: RectanglePainter(
                                startPoint: controller.startPoint,
                                endPoint: controller.endPoint,
                              ),
                              child:
                              Container(color: Colors.transparent),
                            ),
                          );
                        },
                      ),
                      if (controller.isBuffering)
                        const Center(child: CircularProgressIndicator()),
                      if (controller.showControls)
                        buildVideoControls(controller),
                      _buildTextDisplay(controller),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextDisplay(VideoPlayerControllerProvider controller) {
    if (controller.translatedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 10,
      top: 20,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery
              .of(context)
              .size
              .width * 0.8, // 80% of screen width
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Translation',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Use Flexible widget to handle dynamic content height
            Flexible(
              child: Text(
                controller.translatedText.isEmpty
                    ? 'No text extracted or translated yet.'
                    : controller.translatedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                overflow: TextOverflow.visible,
                // Allow text to overflow properly
                softWrap: true, // Allow line breaks for longer text
              ),
            ),
          ],
        ),
      ),
    );
  }
}