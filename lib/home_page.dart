import 'dart:ui';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌙 Soft emotional gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Color(0xFF1A0A2A), // deep violet
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // 🌙 Elegant title (static)
                Text(
                  "SoulNote",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.6,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.purpleAccent.withOpacity(0.5),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ✍️ Poetic, cozy tagline
                Text(
                  "A quiet place where your feelings rest.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 40),

                // 🌫️ Aesthetic Glassmorphic Welcome Card (no animation)
                Expanded(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),

                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 60,
                                color: Colors.white70,
                              ),
                              SizedBox(height: 18),
                              Text(
                                "Your soul is whispering.\nLet your words unfold.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  height: 1.45,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 🖊️ Lovely "Write" Button (simple, aesthetic)
                ElevatedButton(
                  onPressed: () {
                    // will open writing page later
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C72FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    "Write",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
