import 'package:hive/hive.dart';

/// NoteModel WITHOUT build_runner (manual TypeAdapter)
class NoteModel extends HiveObject {
  String title;
  String content;
  DateTime createdAt;

  NoteModel({
    required this.title,
    required this.content,
    required this.createdAt,
  });
}

/// Manual Hive Adapter (typeId = 0)
class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    return NoteModel(
      title: reader.readString(),
      content: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeString(obj.createdAt.toIso8601String());
  }
}
