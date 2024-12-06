import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
part 'models.g.dart';



@HiveType(typeId: 0)
class SettingsModel extends HiveObject {
  @HiveField(0)
  int? containerColor;

  @HiveField(1)
  double? containerOpacity;

  @HiveField(2)
  int? textColor;

  @HiveField(3)
  int? translationDuration;

  @HiveField(4)
  double? textSize;  // Add textSize here


  SettingsModel({
     this.containerColor,
     this.containerOpacity,
     this.textColor,
     this.translationDuration,
     this.textSize,
  });

  // Optional: Add a method to create default settings
  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      containerColor: Colors.black.value,
      containerOpacity: 0.8,
      textColor: Colors.white.value,
      translationDuration: 500,
      textSize: 16.0,  // Correct default value
    );
  }
}
