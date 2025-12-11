import 'package:flutter/material.dart';
import 'package:soul_note/splash_page.dart';
import 'home_page.dart';
import 'splash_page.dart' show SplashPage;
import 'package:soul_note/home_page.dart' show HomePage;

void main() {
  runApp(const SoulNoteApp());
}

class SoulNoteApp extends StatelessWidget {
  const SoulNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoulNote',
      debugShowCheckedModeBanner: false,

      // THEME SETTINGS
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),

      themeMode: ThemeMode.system, // auto theme

      // ROUTES
      initialRoute: "/splash",
      routes: {
        "/splash": (_) => const SplashPage(),
        "/home": (_) => const HomePage(),
      },
    );
  }
}
