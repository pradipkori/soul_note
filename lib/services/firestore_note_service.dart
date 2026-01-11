import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:soul_note/models/note_model.dart';

class FirestoreNoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔄 Upload local note to Firestore (makes it shareable)
  Future<void> uploadNoteToFirestore(NoteModel note) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    await _firestore.collection('notes').doc(note.id).set({
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'createdAt': note.createdAt.toIso8601String(),
      'timeOfDay': note.timeOfDay,
      'mood': note.mood,
      'writingDuration': note.writingDuration,
      'ownerId': currentUser.uid, // ← CRITICAL
      'collaborators': {}, // ← CRITICAL: Empty map initially
      'isShared': true,
    });
  }

  /// ✅ Check if note exists in Firestore
  Future<bool> noteExistsInFirestore(String noteId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('notes')
          .doc(noteId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint("❌ noteExistsInFirestore error: $e");
      return false; // 🔥 IMPORTANT: NEVER hang
    }
  }
}