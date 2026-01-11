import 'package:cloud_firestore/cloud_firestore.dart';

class SharedNoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCollaboratorByEmail({
    required String noteId,
    required String collaboratorEmail,
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
      throw Exception('User with this email not found');
    }

    // STEP 3: Extract UID
    final collaboratorUid = userQuery.docs.first.id;

    // STEP 4: Add collaborator using SET with MERGE (KEY FIX!)
    await _firestore.collection('notes').doc(noteId).set({
      'collaborators': {
        collaboratorUid: true,
      }
    }, SetOptions(merge: true));
  }
}