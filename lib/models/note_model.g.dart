// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      createdAt: fields[3] as DateTime,
      timeOfDay: fields[4] as String,
      mood: fields[5] as String,
      writingDuration: fields[6] as int,
      songs: (fields[7] as List).cast<NoteSong>(),
      isShared: fields[8] as bool,
      ownerId: fields[9] as String,
      collaborators: (fields[10] as List).cast<Collaborator>(),
      lastEditedBy: fields[11] as String,
      lastEditedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.timeOfDay)
      ..writeByte(5)
      ..write(obj.mood)
      ..writeByte(6)
      ..write(obj.writingDuration)
      ..writeByte(7)
      ..write(obj.songs)
      ..writeByte(8)
      ..write(obj.isShared)
      ..writeByte(9)
      ..write(obj.ownerId)
      ..writeByte(10)
      ..write(obj.collaborators)
      ..writeByte(11)
      ..write(obj.lastEditedBy)
      ..writeByte(12)
      ..write(obj.lastEditedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CollaboratorAdapter extends TypeAdapter<Collaborator> {
  @override
  final int typeId = 2;

  @override
  Collaborator read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Collaborator(
      uid: fields[0] as String,
      email: fields[1] as String,
      role: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Collaborator obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.role);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaboratorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
