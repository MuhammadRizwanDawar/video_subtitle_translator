// Custom color picker with modern design
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../../../controllers/setting_controller.dart';

void showColorPicker(BuildContext context, bool isContainerColor) {
  final settingsController = context.read<SettingsController>();
  Color initialColor = isContainerColor
      ? Color(settingsController.currentSettings.containerColor!)
      : Color(settingsController.currentSettings.textColor!);

  showModalBottomSheet(
    backgroundColor: Colors.grey[200],
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Pick ${isContainerColor ? 'Container' : 'Text'} Color',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ),
                Expanded(
                  child: ColorPicker(
                    pickerColor: initialColor,
                    onColorChanged: (Color color) {
                      if (isContainerColor) {
                        settingsController.updateContainerColor(color.value);
                      } else {
                        settingsController.updateTextColor(color.value);
                      }
                    },
                    colorPickerWidth: 300,
                    pickerAreaHeightPercent: 0.8,
                    enableAlpha: false,
                    displayThumbColor: true,
                    paletteType: PaletteType.hueWheel,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Select',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}