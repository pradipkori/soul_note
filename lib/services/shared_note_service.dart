import 'package:cloud_firestore/cloud_firestore.dart';

class SharedNoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCollaboratorByEmail({
    required String noteId,
    required String collaboratorEmail,
    required String role, // owner | editor | viewer
  }) async {
    // STEP 1: Clean email
    final email = collaboratorEmail.trim().toLowerCase();

    // STEP 2: Find user
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('This user hasn\'t registered in Soul Note yet. Ask them to sign up first!');
    }

    // STEP 3: Extract UID
    final collaboratorUid = userQuery.docs.first.id;

    // STEP 4: Add collaborator and ensure isShared is true
    // ✅ Using dot notation 'collaborators.uid' to avoid overwriting the whole map
    await _firestore.collection('notes').doc(noteId).update({
      'isShared': true,
      'collaborators.$collaboratorUid': {
         'role': role,
         'email': email,
      },
    });
  }

  /// 🗑 Remove collaborator
  Future<void> removeCollaborator(String noteId, String uid) async {
    // 1. Remove the collaborator
    await _firestore.collection('notes').doc(noteId).update({
      'collaborators.$uid': FieldValue.delete(),
    });

    // 2. Optional: Re-check if any collaborators left to reset isShared
    final doc = await _firestore.collection('notes').doc(noteId).get();
    if (doc.exists) {
      final collaborators = doc.data()?['collaborators'] as Map<String, dynamic>? ?? {};
      if (collaborators.isEmpty) {
        await _firestore.collection('notes').doc(noteId).update({'isShared': false});
      }
    }
  }
}