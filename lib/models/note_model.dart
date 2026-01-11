import 'package:hive/hive.dart';
import 'note_song.dart';

part 'note_model.g.dart';

/// 🌙 NoteModel with SoulMoments + Songs + Collaboration
@HiveType(typeId: 0)
class NoteModel extends HiveObject {

  // 🆔 Unique ID (used for Firestore shared notes)
  @HiveField(0)
  String id;

  // 📝 Core content
  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime createdAt;

  // 🌙 SoulMoments
  @HiveField(4)
  String timeOfDay;

  @HiveField(5)
  String mood;

  @HiveField(6)
  int writingDuration;

  // 🎵 Songs
  @HiveField(7)
  List<NoteSong> songs;

  // 🤝 Collaboration
  @HiveField(8)
  bool isShared;

  @HiveField(9)
  String ownerId;

  @HiveField(10)
  List<Collaborator> collaborators;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.timeOfDay,
    required this.mood,
    required this.writingDuration,
    this.songs = const [],
    this.isShared = false,
    this.ownerId = '',
    this.collaborators = const [],
  });

  // 📄 Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'timeOfDay': timeOfDay,
      'mood': mood,
      'writingDuration': writingDuration,
      'songs': songs.map((song) => song.toMap()).toList(),
      'isShared': isShared,
      'ownerId': ownerId,
      'collaborators': collaborators.map((c) => c.toMap()).toList(),
    };
  }

  // 📄 Create from Map (from Firestore)
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    // ✅ FIXED: Generate fallback ID if empty
    String noteId = map['id']?.toString() ?? '';
    if (noteId.isEmpty) {
      noteId = '${DateTime.now().millisecondsSinceEpoch}_fallback_${DateTime.now().microsecond}';
    }

    return NoteModel(
      id: noteId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      timeOfDay: map['timeOfDay'] ?? '',
      mood: map['mood'] ?? '',
      writingDuration: map['writingDuration'] ?? 0,
      songs: (map['songs'] as List<dynamic>?)
          ?.map((song) => NoteSong.fromMap(song as Map<String, dynamic>))
          .toList() ??
          [],
      isShared: map['isShared'] ?? false,
      ownerId: map['ownerId'] ?? '',
      collaborators: (map['collaborators'] as List<dynamic>?)
          ?.map((c) => Collaborator.fromMap(c as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

/// 👤 Collaborator Model (Hive-safe)
@HiveType(typeId: 2)
class Collaborator extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String email;

  @HiveField(2)
  String role; // owner | editor | viewer

  Collaborator({
    required this.uid,
    required this.email,
    required this.role,
  });

  // 📄 Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
    };
  }

  // 📄 Create from Map (from Firestore)
  factory Collaborator.fromMap(Map<String, dynamic> map) {
    return Collaborator(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'viewer',
    );
  }
}