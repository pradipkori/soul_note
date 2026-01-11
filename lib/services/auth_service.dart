import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 🔐 Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      // 1️⃣ Trigger Google Sign In
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 2️⃣ Obtain auth details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthCredential credential =
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3️⃣ Firebase sign in
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) return null;

      // 🔥 4️⃣ CREATE / UPDATE USER IN FIRESTORE (CRUCIAL STEP)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        'photoUrl': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// 🚪 Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// 👤 Current User
  User? get currentUser => _auth.currentUser;
}
