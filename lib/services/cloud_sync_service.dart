import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:soul_note/models/note_model.dart';
import 'package:soul_note/storage/hive_boxes.dart';

class CloudSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // 🔼 UPLOAD NOTE (OWNER)
  // =========================
  static Future<void> uploadNote(NoteModel note) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

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
      'collaborators': {
        user.uid: true, // owner is always collaborator
      },
    }, SetOptions(merge: true));

    debugPrint("☁️ Uploaded note ${note.id}");
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

    // ✅ RELIABLE QUERY (OWNER-BASED)
    final snapshot = await _firestore
        .collection('notes')
        .where('ownerId', isEqualTo: user.uid)
        .get();

    debugPrint("📦 Firestore docs found: ${snapshot.docs.length}");

    final box = HiveBoxes.getNotesBox();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final note = NoteModel(
        id: (data['id'] ?? doc.id).toString(),
        title: (data['title'] ?? '').toString(),
        content: (data['content'] ?? '').toString(),
        createdAt: DateTime.tryParse(
          (data['createdAt'] ?? '').toString(),
        ) ??
            DateTime.now(),

        timeOfDay: (data['timeOfDay'] ?? '').toString(),
        mood: (data['mood'] ?? '').toString(),

        writingDuration: data['writingDuration'] is int
            ? data['writingDuration']
            : 0,

        isShared: data['isShared'] == true,
        ownerId: (data['ownerId'] ?? '').toString(),
        songs: const [],
      );


      final exists =
      box.values.any((existing) => existing.id == note.id);

      if (!exists) {
        await box.add(note);
        debugPrint("✅ Restored note ${note.id}");
      } else {
        debugPrint("⚠️ Note already exists ${note.id}");
      }
    }

    debugPrint("🏁 Restore complete. Hive count: ${box.length}");
  }
}
