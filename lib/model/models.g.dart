// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 0;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      containerColor: fields[0] as int?,
      containerOpacity: fields[1] as double?,
      textColor: fields[2] as int?,
      translationDuration: fields[3] as int?,
      textSize: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.containerColor)
      ..writeByte(1)
      ..write(obj.containerOpacity)
      ..writeByte(2)
      ..write(obj.textColor)
      ..writeByte(3)
      ..write(obj.translationDuration)
      ..writeByte(4)
      ..write(obj.textSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
