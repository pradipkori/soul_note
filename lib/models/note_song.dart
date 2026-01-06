import 'package:hive/hive.dart';

class NoteSong {
  String title;
  String artist;
  String previewUrl;
  int startSecond;
  int duration;

  NoteSong({
    required this.title,
    required this.artist,
    required this.previewUrl,
    required this.startSecond,
    required this.duration,
  });
}

class NoteSongAdapter extends TypeAdapter<NoteSong> {
  @override
  final int typeId = 1;

  @override
  NoteSong read(BinaryReader reader) {
    return NoteSong(
      title: reader.readString(),
      artist: reader.readString(),
      previewUrl: reader.readString(),
      startSecond: reader.readInt(),
      duration: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, NoteSong obj) {
    writer
      ..writeString(obj.title)
      ..writeString(obj.artist)
      ..writeString(obj.previewUrl)
      ..writeInt(obj.startSecond)
      ..writeInt(obj.duration);
  }
}
