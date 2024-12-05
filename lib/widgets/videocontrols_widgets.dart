import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/videoPlayer_controller.dart';

buildVideoControls(VideoPlayerControllerProvider controller) {
  return Container(
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
            Consumer<VideoPlayerControllerProvider>(
              builder: (context, controller, _) {
                return IconButton(
                  icon: Icon(
                    controller.isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: controller.toggleFullscreen,
                );
              },
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            buildProgressBar(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Consumer<VideoPlayerControllerProvider>(
                  builder: (context, controller, _) {
                    return Text(
                      '${controller.formatDuration(controller.currentPosition)} / ${controller.formatDuration(controller.videoDuration)}',
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer<VideoPlayerControllerProvider>(
                      builder: (context, controller, _) {
                        return IconButton(
                          icon: Icon(
                            controller.isMuted
                                ? Icons.volume_off
                                : Icons.volume_up,
                            color: Colors.white,
                          ),
                          onPressed: controller.toggleMute,
                        );
                      },
                    ),
                    Consumer<VideoPlayerControllerProvider>(
                      builder: (context, controller, _) {
                        return IconButton(
                          icon: const Icon(
                            Icons.replay_10,
                            color: Colors.white,
                          ),
                          onPressed: () => controller
                              .seekRelative(const Duration(seconds: -10)),
                        );
                      },
                    ),
                    Consumer<VideoPlayerControllerProvider>(
                        builder: (context, controller, _) {
                      return IconButton(
                        icon: Icon(
                          controller.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: controller.togglePlayPause,
                      );
                    }),
                    Consumer<VideoPlayerControllerProvider>(
                      builder: (context, controller, _) {
                        return IconButton(
                          icon: const Icon(
                            Icons.forward_10,
                            color: Colors.white,
                          ),
                          onPressed: () => controller
                              .seekRelative(const Duration(seconds: 10)),
                        );
                      },
                    ),
                    Consumer<VideoPlayerControllerProvider>(
                      builder: (context, controller, _) {
                        return IconButton(
                          icon: const Icon(
                            Icons.speed,
                            color: Colors.white,
                          ),
                          onPressed: controller.changePlaybackSpeed,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

buildProgressBar() {
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
    child: Consumer<VideoPlayerControllerProvider>(
      builder: (context, controller, _) {
        return Slider(
          value: controller.currentPosition.inMilliseconds.toDouble(),
          min: 0,
          max: controller.videoDuration.inMilliseconds.toDouble(),
          onChanged: (value) {
            controller.controller.seekTo(
              Duration(
                milliseconds: value.toInt(),
              ),
            );
          },
        );
      },
    ),
  );
}
