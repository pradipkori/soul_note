import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController glowController;

  @override
  void initState() {
    super.initState();

    // ICON GLOW + FLOAT
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // NAVIGATE HOME
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed("/home");
    });
  }

  @override
  void dispose() {
    glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🌫 Bottom mist
          Positioned(
            bottom: -50,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // ✨ Dust particles
          ...List.generate(25, (i) {
            final r = Random();
            return Positioned(
                top: r.nextDouble() * MediaQuery.of(context).size.height,
                left: r.nextDouble() * MediaQuery.of(context).size.width,
                child: Container(
                  height: 2,
                  width: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: 1200.ms)
                    .fadeOut(duration: 1600.ms));
            }),

          // MAIN CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🌟 ICON WITH GLOW + FLOAT
                AnimatedBuilder(
                  animation: glowController,
                  builder: (context, child) {
                    final glow = 0.15 + glowController.value * 0.10; // stronger glow
                    final floatOffset = sin(glowController.value * 2 * pi) * -2;

                    return Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Container(
                        height: 160,
                        width: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: glow),
                              Colors.transparent,
                            ],
                            radius: 1.0,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.contain,
                  ),
                ).animate().fadeIn(duration: 1200.ms),

                const SizedBox(height: 35),

                // 📝 WORD-BY-WORD HANDWRITTEN EFFECT (FADE + SLIDE)
                WordByWordText(
                  "SoulNote",
                  delay: 800.ms,
                  style: const TextStyle(
                    fontFamily: "Caveat",
                    fontSize: 52,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 14),

                WordByWordText(
                  "Notes that stay close to your soul.",
                  delay: 1400.ms,
                  style: TextStyle(
                    fontFamily: "Caveat",
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                )
                    .animate()
                    .shimmer(
                  duration: 2500.ms,
                  delay: 2500.ms,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌟 WORD BY WORD ANIMATION WIDGET
class WordByWordText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Duration delay;

  const WordByWordText(this.text,
      {super.key, required this.style, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    final words = text.split(" ");

    return Wrap(
      alignment: WrapAlignment.center,
      children: List.generate(words.length, (i) {
        return Text("${words[i]} ", style: style)
            .animate()
            .fadeIn(
          delay: delay + Duration(milliseconds: i * 250),
          duration: 500.ms,
        )
            .moveY(
          begin: 12,
          end: 0,
          duration: 600.ms,
          delay: delay + Duration(milliseconds: i * 250),
          curve: Curves.easeOutCubic,
        )
            .shake(
          hz: 1,
          offset: const Offset(0.5, 0),
          duration: 400.ms,
          delay: delay + Duration(milliseconds: i * 250),
        );
      }),
    );
  }
}
