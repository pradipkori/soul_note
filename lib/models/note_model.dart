import 'package:hive/hive.dart';
import 'note_song.dart';

/// 🌙 NoteModel with SoulMoments + Songs
class NoteModel extends HiveObject {
  // 📝 Core content
  String title;
  String content;
  DateTime createdAt;

  // 🌙 SoulMoments
  String timeOfDay;        // Morning / Afternoon / Evening / Late Night
  String mood;             // Calm / Happy / Heavy / etc.
  int writingDuration;     // in seconds

  // 🎵 Attached Songs
  List<NoteSong> songs;

  NoteModel({
    required this.title,
    required this.content,
    required this.createdAt,
    required this.timeOfDay,
    required this.mood,
    required this.writingDuration,
    this.songs = const [],
  });
}

/// 🔐 Hive Adapter for NoteModel (typeId = 0)
class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    return NoteModel(
      title: reader.readString(),
      content: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
      timeOfDay: reader.readString(),
      mood: reader.readString(),
      writingDuration: reader.readInt(),
      songs: reader.readList().cast<NoteSong>(),
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeString(obj.title)
      ..writeString(obj.content)
      ..writeString(obj.createdAt.toIso8601String())
      ..writeString(obj.timeOfDay)
      ..writeString(obj.mood)
      ..writeInt(obj.writingDuration)
      ..writeList(obj.songs);
  }
}
