import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'splash_page.dart';
import 'home_page.dart';
import 'models/note_model.dart';
import 'storage/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Initialize Hive
  await Hive.initFlutter();

  // 📌 Register NoteModel Adapter
  Hive.registerAdapter(NoteModelAdapter());

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

      // 🌗 THEMES
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),

      themeMode: ThemeMode.system, // auto theme switch

      // 🗺 ROUTES
      initialRoute: "/splash",
      routes: {
        "/splash": (context) => const SplashPage(),
        "/home": (context) => const HomePage(),
      },
    );
  }
}
