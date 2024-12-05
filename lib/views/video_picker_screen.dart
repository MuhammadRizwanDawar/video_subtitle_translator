import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/video_controller.dart';
import '../widgets/languagedropdown.dart';

class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  _VideoPickerScreenState createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  late LanguageChooseController languageChooseController;

  @override
  void initState() {
    super.initState();
    languageChooseController =
        Provider.of<LanguageChooseController>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Video Translator',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xff5565FD),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Consumer<LanguageChooseController>(
              builder: (context, controller, _) {
                return LanguageDropdownWidget(
                  value: controller.sourceLanguage,
                  title: 'Translate from',
                  onChanged: (String? newValue) {
                    controller.changeSourceLanguage(newValue, context);
                  },
                );
              },
            ),
            Consumer<LanguageChooseController>(
              builder: (context, controller, _) {
                return LanguageDropdownWidget(
                  value: controller.targetLanguage,
                  title: 'Translate to',
                  onChanged: (String? newValue) {
                    controller.changeTargetLanguage(newValue, context);
                  },
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer<LanguageChooseController>(
                builder: (context, controller, _) {
                  return ElevatedButton(
                    onPressed: () {
                      if (controller.downloadedModels[
                                  controller.sourceLanguage] ==
                              true &&
                          controller.downloadedModels[
                                  controller.targetLanguage] ==
                              true) {
                        controller.pickAndNavigateToVideo(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please download both language models first'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff5565FD),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, size: 24,color: Colors.white,),
                        SizedBox(width: 12),
                        Text(
                          'Choose Video',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
