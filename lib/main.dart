import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'package:soul_note/splash_page.dart';
import 'package:soul_note/home_page.dart';
import 'package:soul_note/auth/google_login_page.dart';

import 'package:soul_note/models/note_model.dart';
import 'package:soul_note/models/note_song.dart';
import 'package:soul_note/models/drawing_stroke.dart';
import 'package:soul_note/storage/hive_boxes.dart';
import 'package:soul_note/firebase_options.dart';

Future<void> handleEmailLinkSignIn() async {
  final auth = FirebaseAuth.instance;
  final link = Uri.base.toString();

  if (!auth.isSignInWithEmailLink(link)) {
    debugPrint("Not an email sign-in link: $link");
    return;
  }


  final email = auth.currentUser?.email;

  if (email == null) {
    debugPrint("Email required to complete sign-in");
    return;
  }

  try {
    await auth.signInWithEmailLink(
      email: email,
      emailLink: link,
    );
  } catch (e) {
    debugPrint("Email link sign-in failed: $e");
  }
}



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
  );


  // 🗄 Initialize Hive
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(NoteModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(NoteSongAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CollaboratorAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(DrawingPointAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(DrawingStrokeAdapter());
  }


  // 📦 Open notes box (with crash recovery)
  try {
    await Hive.openBox<NoteModel>(HiveBoxes.notesBox);
  } catch (e) {
    debugPrint("🚨 Error opening Hive box: $e. Corrupted data likely from removed features. Clearing box...");
    await Hive.deleteBoxFromDisk(HiveBoxes.notesBox);
    await Hive.openBox<NoteModel>(HiveBoxes.notesBox);
  }

  // 🔐 Handle email link login BEFORE app starts
  await handleEmailLinkSignIn();

  runApp(const SoulNoteApp());
}

class SoulNoteApp extends StatelessWidget {
  const SoulNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoulNote',
      debugShowCheckedModeBanner: false,

      // 🌗 LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),

      // 🌑 DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),

      themeMode: ThemeMode.system,

      // ✅ START FROM SPLASH
      home: const SplashPage(),
    );
  }
}

/// 🔐 SINGLE SOURCE OF TRUTH FOR AUTH
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ Logged in
        if (snapshot.hasData) {
          return HomePage(
            ownerId: snapshot.data!.uid,
            isGuest: false,
          );
        }

        // ❌ Not logged in
        return const GoogleLoginPage();
      },
    );
  }
}
