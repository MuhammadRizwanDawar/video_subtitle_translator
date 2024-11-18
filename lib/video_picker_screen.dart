import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'video_player_screen.dart';

class VideoPickerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pick a Video')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final videoPath = await _pickVideo();
            if (videoPath != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(videoPath: videoPath),
                ),
              );
            }
          },
          child: Text('Pick Video from Gallery'),
        ),
      ),
    );
  }

  Future<String?> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    return pickedFile?.path;
  }
}


