import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:video_subtitle_translator/controllers/setting_controller.dart';

import 'component/setting_component/color_picker_widget.dart';
import 'component/setting_component/section_setting_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsController settingsController;

  @override
  void initState() {
    super.initState();
    settingsController =
        Provider.of<SettingsController>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<SettingsController>(
                builder: (context, controller, _) {
                  return SettingsSection(
                    title: 'Translation Container Color',
                    subtitle: 'Customize the background of subtitles',
                    trailing: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            Color(controller.currentSettings.containerColor!),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueGrey.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                    onTap: () => showColorPicker(context, true),
                  );
                },
              ),

              Consumer<SettingsController>(
                builder: (context, controller, _) {
                  return SettingsSection(
                    title: 'Translation Container Opacity',
                    subtitle: 'Adjust the transparency of subtitle container',
                    trailing: SizedBox(
                      width: 150,
                      child: CupertinoSlider(
                        value: controller.currentSettings.containerOpacity!,
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.blueAccent,
                        onChanged: (double value) {
                          controller.updateContainerOpacity(value);
                        },
                      ),
                    ),
                  );
                },
              ),
              // Text Color Section
              Consumer<SettingsController>(
                builder: (context, controller, _) {
                  return SettingsSection(
                    title: 'Subtitle Text Color',
                    subtitle: 'Choose the color of subtitle text',
                    trailing: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(controller.currentSettings.textColor!),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueGrey.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                    onTap: () => showColorPicker(context, false),
                  );
                },
              ),

              Consumer<SettingsController>(
                builder: (context, controller, _) {
                  return SettingsSection(
                    title: 'Text Size',
                    subtitle: 'Adjust the size of the text',
                    trailing: Column(
                      children: [
                        if (controller.currentSettings.textSize != null)
                          Text(
                            'Size: ${(controller.currentSettings.textSize)}',
                            style: TextStyle(
                                fontSize: controller.currentSettings.textSize),
                          ),
                        if (controller.currentSettings.textSize != null)
                          Slider(
                            value: controller.currentSettings.textSize!,
                            min: 10.0,
                            max: 30.0,
                            divisions: 20,
                            label:
                                controller.currentSettings.textSize.toString(),
                            onChanged: (double value) {
                              controller.updateTextSize(value);
                            },
                          ),
                      ],
                    ),
                    onTap: () {
                      // Handle tap if needed
                    },
                  );
                },
              ),

              // Translation Duration Section
              Consumer<SettingsController>(
                builder: (context, controller, _) {
                  return SettingsSection(
                    title: 'Translation Duration',
                    subtitle: 'Set the speed of subtitle translation',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${controller.currentSettings.translationDuration} ms',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        backgroundColor: Colors.white,
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(35.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Select Translation Duration',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children:
                                      [500, 1000, 1500, 2000].map((duration) {
                                    return ChoiceChip(
                                      label: Text('$duration ms'),
                                      selected: controller.currentSettings
                                              .translationDuration ==
                                          duration,
                                      onSelected: (bool selected) {
                                        if (selected) {
                                          controller.updateTranslationDuration(
                                              duration);
                                          Navigator.pop(context);
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Consumer<SettingsController>(
                  builder: (context, controller, _) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        controller.resetToDefaultSettings();
                      },
                      icon: const Icon(
                        Icons.restore,
                        size: 24,
                        color: Colors.white, // White icon for better contrast
                      ),
                      label: const Text(
                        'Reset to Default',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white, // White text for better contrast
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16), // Removed bold for consistency
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
