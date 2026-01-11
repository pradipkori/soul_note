import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:soul_note/models/note_model.dart';
import 'package:soul_note/models/note_song.dart';
import 'package:soul_note/storage/hive_boxes.dart';

class CloudSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // 🔼 UPLOAD NOTE (CREATE)
  // =========================
  static Future<void> uploadNote(NoteModel note) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _firestore.collection('notes').doc(note.id).set({
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'createdAt': note.createdAt.toIso8601String(),
      'timeOfDay': note.timeOfDay,
      'mood': note.mood,
      'writingDuration': note.writingDuration,
      'ownerId': user.uid,
      'isShared': note.isShared,
      'collaborators': {user.uid: true},

      // 🎵 SONGS (MATCH NoteSong MODEL)
      'songs': note.songs.map((song) => {
        'title': song.title,
        'artist': song.artist,
        'previewUrl': song.previewUrl,
        'startSecond': song.startSecond,
        'duration': song.duration,
      }).toList(),

    }, SetOptions(merge: true));

    debugPrint("☁️ Uploaded note ${note.id}");
  }

  // =========================
  // 🗑️ DELETE NOTE (OWNER)
  // =========================
  static Future<void> deleteNote(String noteId) async {
    final user = _auth.currentUser;

    if (user == null) {
      debugPrint("❌ Delete aborted: user is null");
      return;
    }

    await _firestore
        .collection('notes')
        .doc(noteId)
        .delete();

    debugPrint("🗑️ Deleted note from cloud: $noteId");
  }

  // =========================
  // ✏️ UPDATE NOTE (TWO-WAY SYNC)
  // =========================
  static Future<void> updateNote(NoteModel note) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("❌ Update aborted: user is null");
      return;
    }

    await _firestore.collection('notes').doc(note.id).set({
      'title': note.title,
      'content': note.content,
      'timeOfDay': note.timeOfDay,
      'mood': note.mood,
      'writingDuration': note.writingDuration,
      'updatedAt': DateTime.now().toIso8601String(),

      // 🎵 UPDATE SONGS
      'songs': note.songs.map((song) => {
        'title': song.title,
        'artist': song.artist,
        'previewUrl': song.previewUrl,
        'startSecond': song.startSecond,
        'duration': song.duration,
      }).toList(),

    }, SetOptions(merge: true));

    debugPrint("✏️ Updated note in cloud: ${note.id}");
  }

  // =========================
  // 🔽 RESTORE NOTES (ON LOGIN)
  // =========================
  static Future<void> restoreNotesFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("❌ Restore aborted: user is null");
      return;
    }

    debugPrint("🔄 Restore started for uid: ${user.uid}");

    final snapshot = await _firestore
        .collection('notes')
        .where('ownerId', isEqualTo: user.uid)
        .get();

    debugPrint("📦 Firestore docs found: ${snapshot.docs.length}");

    final box = HiveBoxes.getNotesBox();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final List songsData = data['songs'] ?? [];

      final note = NoteModel(
        id: data['id'],
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        createdAt: DateTime.parse(data['createdAt']),
        timeOfDay: data['timeOfDay'] ?? '',
        mood: data['mood'] ?? '',
        writingDuration: data['writingDuration'] ?? 0,
        isShared: data['isShared'] ?? false,
        ownerId: data['ownerId'] ?? '',

        // 🎵 RESTORE SONGS
        songs: songsData.map((s) => NoteSong(
          title: s['title'] ?? '',
          artist: s['artist'] ?? '',
          previewUrl: s['previewUrl'] ?? '',
          startSecond: s['startSecond'] ?? 0,
          duration: s['duration'] ?? 0,
        )).toList(),

      );

      final exists = box.values.any((n) => n.id == note.id);

      if (!exists) {
        await box.add(note);
        debugPrint("✅ Restored note ${note.id}");
      }
    }

    debugPrint("🏁 Restore complete. Hive count: ${box.length}");
  }
}