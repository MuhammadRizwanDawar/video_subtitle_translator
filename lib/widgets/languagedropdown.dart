import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/video_controller.dart';

class LanguageDropdownWidget extends StatelessWidget {
  final String value;
  final String title;
  final Function(String?) onChanged;

  const LanguageDropdownWidget({
    Key? key,
    required this.value,
    required this.title,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageChooseController>(
      builder: (context, controller, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 14),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.deepPurpleAccent,
                    ),
                    items: controller.languageNames.entries.map((entry) {
                      bool isDownloaded =
                          controller.downloadedModels[entry.key] == true;
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: _buildLanguageItem(
                            context, entry, isDownloaded, controller),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        if (controller.downloadedModels[newValue] == true) {
                          onChanged(newValue);
                        } else {
                          _showDownloadDialog(
                              context,
                              newValue,
                              controller.languageNames[newValue] ?? 'Language',
                              controller);
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(
      BuildContext context,
      MapEntry<String, String> entry,
      bool isDownloaded,
      LanguageChooseController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          entry.value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey[800],
          ),
        ),
        _buildStatusIndicator(isDownloaded),
      ],
    );
  }

  Widget _buildStatusIndicator(bool isDownloaded) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isDownloaded
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 18,
              ),
            )
          : Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download,
                color: Colors.blue,
                size: 18,
              ),
            ),
    );
  }

  void _showDownloadDialog(BuildContext context, String languageCode,
      String languageName, LanguageChooseController controller) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Download $languageName Model',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The $languageName language model is not downloaded. Would you like to download it now?',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      controller.downloadModel(languageCode, context);
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text(
                      'Download',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
