// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardInfoAdapter extends TypeAdapter<CardInfo> {
  @override
  final int typeId = 1;

  @override
  CardInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardInfo(
      target: fields[0] as String,
      sign: fields[1] as String,
      content: fields[2] as String,
      key: fields[3] as String,
      time: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CardInfo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.target)
      ..writeByte(1)
      ..write(obj.sign)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.key)
      ..writeByte(4)
      ..write(obj.time);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
