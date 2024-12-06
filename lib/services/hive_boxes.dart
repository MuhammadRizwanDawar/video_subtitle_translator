import 'package:hive_flutter/adapters.dart';
import 'package:video_subtitle_translator/model/models.dart';

class HiveBoxes {
  static Future<void> open() async {
    await Hive.openBox<SettingsModel>('settings_box');
  }
}