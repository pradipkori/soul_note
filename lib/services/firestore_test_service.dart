import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTestService {
  static Future<void> writeTestNote() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await FirebaseFirestore.instance.collection('notes').add({
      'title': 'Hello Firestore',
      'content': 'This is a test note',
      'ownerId': user.uid,
      'collaborators': {
        user.uid: true, // owner is also collaborator
      },
      'createdAt': Timestamp.now(),
    });
  }
}
