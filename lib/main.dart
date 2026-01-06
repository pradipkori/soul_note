import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'splash_page.dart';
import 'home_page.dart';
import 'models/note_model.dart';
import 'models/note_song.dart';
import 'storage/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Initialize Hive
  await Hive.initFlutter();

  // 🔐 Register adapters safely (VERY IMPORTANT)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(NoteModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(NoteSongAdapter());
  }

  // 📦 Open notes box
  await Hive.openBox<NoteModel>(HiveBoxes.notesBox);

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

      // 🗺 ROUTES
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
