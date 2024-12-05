import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';
import '../languages list/languages.dart';
import '../views/video_player_screen.dart';

class LanguageChooseController extends ChangeNotifier {
  String sourceLanguage = 'en';
  String targetLanguage = 'es';
  bool isLoading = false;
  Map<String, bool> downloadedModels = {};
  final Map<String, String> languageNames = LanguagesList().languageNames;
  List<String> languages = LanguagesList().languages;

  String? selectedVideoPath;


  final OnDeviceTranslatorModelManager modelManager =
  OnDeviceTranslatorModelManager();

  LanguageChooseController() {
    _initializeLanguageModels();
  }

  Future<void> _initializeLanguageModels() async {
    isLoading = true;
    notifyListeners();
    for (String code in languageNames.keys) {
      bool isDownloaded = await modelManager.isModelDownloaded(code);
      downloadedModels[code] = isDownloaded;
      notifyListeners();
    }
    isLoading = false;
    notifyListeners();
  }

  // Method to download the language model if it is not already downloaded
  Future<void> downloadModel(String language, BuildContext context) async {
    if (downloadedModels[language] == true) return;

    isLoading = true;
    notifyListeners();

    try {
      await modelManager.downloadModel(language);
      downloadedModels[language] = true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${languageNames[language]} model downloaded successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download ${languageNames[language]} model'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Handle source language change and update model if needed
  Future<void> changeSourceLanguage(String? newLanguage, BuildContext context) async {
    if (newLanguage == null) return;
    sourceLanguage = newLanguage;
    notifyListeners();
    if (downloadedModels[sourceLanguage] != true) {
      await downloadModel(sourceLanguage, context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${languageNames[sourceLanguage]} model is already downloaded'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Handle target language change and update model if needed
  Future<void> changeTargetLanguage(String? newLanguage, BuildContext context) async {
    if (newLanguage == null) return;
    targetLanguage = newLanguage;
    notifyListeners();
    if (downloadedModels[targetLanguage] != true) {
      await downloadModel(targetLanguage, context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${languageNames[targetLanguage]} model is already downloaded'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> pickAndNavigateToVideo(BuildContext context) async {
    if (!downloadedModels[sourceLanguage]! || !downloadedModels[targetLanguage]!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please download both language models first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null && pickedFile.path.isNotEmpty) {
        selectedVideoPath = pickedFile.path;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VideoPlayerScreen(),
          ),
        );
        notifyListeners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No video selected.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick a video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Get the selected video path from the controller
  String? getSelectedVideoPath() {
    return selectedVideoPath;
  }
}
