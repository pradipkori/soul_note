import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================
  // 🔐 GOOGLE SIGN-IN
  // =========================
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception("Google sign-in cancelled");
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    
    // ✅ SYNC USER DATA TO FIRESTORE
    if (userCredential.user != null) {
      await _updateUserProfile(userCredential.user!);
    }
    
    return userCredential;
  }

  // =========================
  // 👤 UPDATE USER DATA
  // =========================
  Future<void> _updateUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email?.toLowerCase().trim() ?? '',
      'displayName': user.displayName ?? '',
      'photoUrl': user.photoURL ?? '',
      'lastSignIn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =========================
  // 📧 EMAIL SIGN-IN (SAFE)
  // =========================
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Try normal email login
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // 🔥 THIS IS THE IMPORTANT PART
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          "This email is already linked with Google. Please sign in with Google first.",
        );
      }
      rethrow;
    }
  }

  // =========================
  // 🔗 LINK EMAIL TO GOOGLE
  // =========================
  Future<void> linkEmailToCurrentUser({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("No logged-in user to link");
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.linkWithCredential(credential);
  }

  // =========================
  // 🚪 SIGN OUT
  // =========================
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
