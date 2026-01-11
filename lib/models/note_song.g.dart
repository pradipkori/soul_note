// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteSongAdapter extends TypeAdapter<NoteSong> {
  @override
  final int typeId = 1;

  @override
  NoteSong read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteSong(
      title: fields[0] as String,
      artist: fields[1] as String,
      previewUrl: fields[2] as String,
      startSecond: fields[3] as int,
      duration: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NoteSong obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.artist)
      ..writeByte(2)
      ..write(obj.previewUrl)
      ..writeByte(3)
      ..write(obj.startSecond)
      ..writeByte(4)
      ..write(obj.duration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteSongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
