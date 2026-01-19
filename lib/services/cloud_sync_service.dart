import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:soul_note/models/note_model.dart';
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
      'lastEditedBy': note.lastEditedBy,
      'lastEditedAt': note.lastEditedAt?.toIso8601String(),

      // 🎵 SONGS (MATCH NoteSong MODEL)
      'songs': note.songs.map((song) => {
        'title': song.title,
        'artist': song.artist,
        'previewUrl': song.previewUrl,
        'startSecond': song.startSecond,
        'duration': song.duration,
      }).toList(),

      // 🎨 DRAWING
      'drawingStrokes': note.drawingStrokes.map((s) => s.toMap()).toList(),

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
      'lastEditedBy': note.lastEditedBy,
      'lastEditedAt': note.lastEditedAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),

      // 🎵 UPDATE SONGS
      'songs': note.songs.map((song) => {
        'title': song.title,
        'artist': song.artist,
        'previewUrl': song.previewUrl,
        'startSecond': song.startSecond,
        'duration': song.duration,
      }).toList(),

      // 🎨 DRAWING
      'drawingStrokes': note.drawingStrokes.map((s) => s.toMap()).toList(),

    }, SetOptions(merge: true));

    debugPrint("✏️ Updated note in cloud: ${note.id} by ${note.lastEditedBy}");
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

    // 1️⃣ Fetch owned notes
    final ownedSnapshot = await _firestore
        .collection('notes')
        .where('ownerId', isEqualTo: user.uid)
        .get();

    // 2️⃣ Fetch shared notes (where uid exists in collaborators map)
    // NOTE: This might require a composite index if combined with other fields
    final sharedSnapshot = await _firestore
        .collection('notes')
        .where('collaborators.${user.uid}.role', whereIn: ['editor', 'viewer', 'owner'])
        .get();

    debugPrint("📦 Owned docs: ${ownedSnapshot.docs.length}, Shared docs: ${sharedSnapshot.docs.length}");

    final box = HiveBoxes.getNotesBox();
    final allDocs = [...ownedSnapshot.docs, ...sharedSnapshot.docs];

    // Deduplicate if any doc is in both (shouldn't happen with these queries but good practice)
    final Map<String, DocumentSnapshot> uniqueDocs = {};
    for (var doc in allDocs) {
      uniqueDocs[doc.id] = doc;
    }

    for (final doc in uniqueDocs.values) {
      final data = doc.data() as Map<String, dynamic>;
      final note = NoteModel.fromMap(data);

      final exists = box.values.any((n) => n.id == note.id);

      if (!exists) {
        await box.add(note);
        debugPrint("✅ Restored note ${note.id}");
      } else {
        // Sync update: If cloud note has a newer lastEditedAt, update local.
        final localNote = box.values.firstWhere((n) => n.id == note.id);
        final cloudTime = note.lastEditedAt ?? note.createdAt;
        final localTime = localNote.lastEditedAt ?? localNote.createdAt;

        if (cloudTime.isAfter(localTime)) {
           final index = box.values.toList().indexOf(localNote);
           await box.putAt(index, note);
           debugPrint("🔄 Updated local note ${note.id} from cloud (Cloud: $cloudTime > Local: $localTime)");
        }
      }
    }

    debugPrint("🏁 Restore complete. Hive count: ${box.length}");
  }

  // =========================
  // 📡 REAL-TIME SYNC (SINGLE NOTE)
  // =========================
  static Stream<NoteModel?> streamNote(String noteId) {
    return _firestore.collection('notes').doc(noteId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return NoteModel.fromMap(snapshot.data()!);
    });
  }
}