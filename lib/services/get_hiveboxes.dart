import 'package:hive_flutter/adapters.dart';
import 'package:video_subtitle_translator/model/models.dart';

class GetHiveBoxes {
  static Box<SettingsModel> get settingsBox => Hive.box('settings_box');
}