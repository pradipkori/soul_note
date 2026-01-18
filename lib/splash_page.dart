import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_page.dart';
import 'auth/google_login_page.dart'; // ✅ NEW
import 'package:firebase_auth/firebase_auth.dart'; // ✅ NEW// <-- IMPORTANT

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController glowController;
  late AnimationController writeController;

  @override
  void initState() {
    super.initState();

    // 🌟 GLOW + FLOAT ANIMATION
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // ✍ LETTER-BY-LETTER WRITE ANIMATION
    writeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) writeController.forward();
    });

    // AFTER ANIMATION → GO TO HOME
    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: user != null
                ? HomePage(
              ownerId: user.uid,
              isGuest: false,
            )
                : const GoogleLoginPage(),

          ),
        ),
      );
    });

  }

  @override
  void dispose() {
    glowController.dispose();
    writeController.dispose();
    super.dispose();
  }

  // ⭐ LETTER BY LETTER WRITING WIDGET
  Widget buildHandwritingTitle() {
    const text = "SoulNote";

    return AnimatedBuilder(
      animation: writeController,
      builder: (context, _) {
        int visibleLetters =
        (writeController.value * text.length).floor();

        return Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(text.length, (i) {
            bool show = i < visibleLetters;

            return AnimatedOpacity(
              opacity: show ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedSlide(
                offset: show ? Offset.zero : const Offset(0.2, 0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: Text(
                  text[i],
                  style: const TextStyle(
                    fontFamily: "Caveat",
                    fontSize: 52,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          // 🌫 Bottom mist
          Positioned(
            bottom: -60,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.10),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // ✨ Dust particles
          ...List.generate(28, (index) {
            final r = Random();
            return Positioned(
              top: r.nextDouble() * MediaQuery.of(context).size.height,
              left: r.nextDouble() * MediaQuery.of(context).size.width,
              child: Container(
                height: 2,
                width: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 1200.ms)
                  .fadeOut(duration: 1800.ms),
            );
          }),

          // MAIN CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🌙 Icon with soft breathing glow
                AnimatedBuilder(
                  animation: glowController,
                  builder: (context, child) {
                    final glow =
                        0.16 + glowController.value * 0.12; // slightly stronger glow
                    final floatOffset =
                        sin(glowController.value * 2 * pi) * -2;

                    return Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(glow),
                              blurRadius: 45,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset("assets/images/logo.png"),
                ),

                const SizedBox(height: 30),

                // ✍ Handwriting Title
                buildHandwritingTitle(),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  "Notes that stay close to your soul.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Caveat",
                    fontSize: 24,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ).animate().fadeIn(duration: 1200.ms, delay: 1400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
