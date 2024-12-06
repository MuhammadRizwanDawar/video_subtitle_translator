import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';
import '../model/models.dart';
import '../services/get_hiveboxes.dart';

class SettingsController extends ChangeNotifier{
  late Box<SettingsModel> _settingsBox;
  late SettingsModel _currentSettings;

  SettingsModel get currentSettings => _currentSettings;

  SettingsController() {
    _initializeSettings();
  }
  void _initializeSettings() {
    _settingsBox = GetHiveBoxes.settingsBox;
    if (_settingsBox.isEmpty) {
      _currentSettings = SettingsModel.defaultSettings();
      _settingsBox.add(_currentSettings);
    } else {
      _currentSettings = _settingsBox.getAt(0)!;
    }
  }
  void updateContainerColor(int color) {
    _currentSettings.containerColor = color;
    saveSettings();
    notifyListeners();
  }

  void updateTextColor(int color) {
    _currentSettings.textColor = color;
    saveSettings();
    notifyListeners();
  }

  void updateContainerOpacity(double opacity) {
    _currentSettings.containerOpacity = opacity;
    saveSettings();
    notifyListeners();
  }

  void updateTranslationDuration(int duration) {
    _currentSettings.translationDuration = duration;
    saveSettings();
    notifyListeners();
  }

  void updateTextSize(double size) {
    _currentSettings.textSize = size;
    log("Text size updated to: $size");
    saveSettings();
    notifyListeners();
  }



  void saveSettings() {
    if (_settingsBox.isEmpty) {
      _settingsBox.add(_currentSettings);
    } else {
      _settingsBox.putAt(0, _currentSettings);
    }
    // Log the saved color values
    log("Saved container color: ${_currentSettings.containerColor}");
    log("Saved text color: ${_currentSettings.textColor}");
    log("Saved container opacity: ${_currentSettings.containerOpacity}");
    log("Saved translation duration: ${_currentSettings.translationDuration}");
    notifyListeners();
  }

  void resetToDefaultSettings() {
    _currentSettings = SettingsModel.defaultSettings();
    saveSettings();
    notifyListeners();
  }


}