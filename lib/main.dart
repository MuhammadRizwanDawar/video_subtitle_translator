import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:video_subtitle_translator/controllers/setting_controller.dart';
import 'package:video_subtitle_translator/controllers/video_controller.dart';
import 'package:video_subtitle_translator/services/hive_adapter.dart';
import 'package:video_subtitle_translator/services/hive_boxes.dart';
import 'package:video_subtitle_translator/views/video_picker_screen.dart';

import 'controllers/videoPlayer_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  registerDataBaseAdapters();
  await HiveBoxes.open();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageChooseController()),
        ChangeNotifierProvider(create: (_) => VideoPlayerControllerProvider()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Translator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VideoPickerScreen(),
    );
  }
}
