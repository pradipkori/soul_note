import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollaborationTestService {
  static Future<void> addTestCollaborator({
    required String noteId,
    required String collaboratorEmail,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    // 1️⃣ Find user by email
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: collaboratorEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception("No user found with this email");
    }

    final collaboratorUid = userQuery.docs.first.id;

    // 2️⃣ Add collaborator UID to note
    await FirebaseFirestore.instance
        .collection('notes')
        .doc(noteId)
        .set({
      'collaborators': {
        collaboratorUid: true,
      }
    }, SetOptions(merge: true));
  }
}
