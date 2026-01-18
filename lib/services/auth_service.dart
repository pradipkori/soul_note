import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    return await _auth.signInWithCredential(credential);
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
