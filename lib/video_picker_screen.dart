import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:video_subtitle_translator/utlis/languages.dart';
import 'package:video_subtitle_translator/video_player_screen.dart';

class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  _VideoPickerScreenState createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  String sourceLanguage = 'en';
  String targetLanguage = 'es';
  bool isLoading = false;
  Map<String, bool> downloadedModels = {};
    final Map<String, String> languageNames = LanguagesList().languageNames;
  List<String> languages = LanguagesList().languages;

  final OnDeviceTranslatorModelManager modelManager = OnDeviceTranslatorModelManager();

  @override
  void initState() {
    super.initState();
    _initializeLanguageModels();
  }

  Future<void> _initializeLanguageModels() async {
    setState(() => isLoading = true);

    for (String code in languageNames.keys) {
      bool isDownloaded = await modelManager.isModelDownloaded(code);
      if (mounted) {
        setState(() {
          downloadedModels[code] = isDownloaded;
        });
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _downloadModel(String language) async {
    if (downloadedModels[language] == true) return;

    setState(() => isLoading = true);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 20),
                Text(
                  'Downloading ${languageNames[language]} model...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await modelManager.downloadModel(language);
      if (mounted) Navigator.of(context).pop();
      setState(() {
        downloadedModels[language] = true;
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${languageNames[language]} model downloaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${languageNames[language]} model'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLanguageDropdown({
    required String value,
    required String title,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton<String>(
                        value: value,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                        items: languageNames.entries.map((entry) {
                          bool isDownloaded = downloadedModels[entry.key] == true;
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isDownloaded)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: () {
                                      _downloadModel(entry.key);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.download,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            onChanged(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndNavigateToVideo() async {
    if (!downloadedModels[sourceLanguage]! || !downloadedModels[targetLanguage]!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please download both language models first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile?.path != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoPath: pickedFile!.path,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Video Translator',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildLanguageDropdown(
              value: sourceLanguage,
              title: 'Translate from',
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => sourceLanguage = newValue);
                  if (downloadedModels[newValue] != true) {
                    _downloadModel(newValue);
                  }
                }
              },
            ),
            _buildLanguageDropdown(
              value: targetLanguage,
              title: 'Translate to',
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => targetLanguage = newValue);
                  if (downloadedModels[newValue] != true) {
                    _downloadModel(newValue);
                  }
                }
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: isLoading ? null : _pickAndNavigateToVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_library, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Choose Video',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

