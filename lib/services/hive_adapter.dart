import 'package:hive_flutter/adapters.dart';
import 'package:video_subtitle_translator/model/models.dart';

void registerDataBaseAdapters() {
  Hive.registerAdapter(SettingsModelAdapter());
}
