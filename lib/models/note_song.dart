import 'package:hive/hive.dart';

part 'note_song.g.dart';

@HiveType(typeId: 1)
class NoteSong extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String artist;

  @HiveField(2)
  String previewUrl;

  @HiveField(3)
  int startSecond;

  @HiveField(4)
  int duration;

  NoteSong({
    required this.title,
    required this.artist,
    required this.previewUrl,
    required this.startSecond,
    required this.duration,
  });

  // 🔄 Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'previewUrl': previewUrl,
      'startSecond': startSecond,
      'duration': duration,
    };
  }

  // 🔄 Create from Map (from Firestore)
  factory NoteSong.fromMap(Map<String, dynamic> map) {
    return NoteSong(
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      previewUrl: map['previewUrl'] ?? '',
      startSecond: map['startSecond'] ?? 0,
      duration: map['duration'] ?? 30,
    );
  }
}