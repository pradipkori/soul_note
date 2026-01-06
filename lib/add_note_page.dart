import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'models/note_model.dart';
import 'models/note_song.dart';
import 'storage/hive_boxes.dart';
import 'utils/soul_moment_utils.dart';
import 'song_search_page.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> with SingleTickerProviderStateMixin {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();

  DateTime? startTime;
  String selectedMood = "Calm 🌿";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isAnalyzingMood = false;

  final List<NoteSong> _songs = [];

  // Modern color scheme
  final Color primaryColor = const Color(0xFF6366F1); // Indigo
  final Color secondaryColor = const Color(0xFF8B5CF6); // Purple
  final Color accentColor = const Color(0xFFEC4899); // Pink
  final Color backgroundColor = const Color(0xFF0F172A); // Dark slate
  final Color surfaceColor = const Color(0xFF1E293B); // Lighter slate

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    // Listen to content changes for auto mood detection
    contentCtrl.addListener(_autoDetectMood);
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Auto mood detection based on content
  void _autoDetectMood() {
    if (contentCtrl.text.length < 20) return;

    final text = contentCtrl.text.toLowerCase();
    String detectedMood = "Calm 🌿";

    // Keyword-based mood detection
    final happyWords = ['happy', 'joy', 'excited', 'great', 'amazing', 'wonderful', 'love', 'blessed', 'grateful'];
    final heavyWords = ['sad', 'tired', 'exhausted', 'hard', 'difficult', 'painful', 'hurt', 'miss', 'alone'];
    final lovedWords = ['love', 'heart', 'care', 'appreciate', 'cherish', 'adore', 'romance', 'together'];
    final stressedWords = ['stress', 'anxiety', 'worried', 'nervous', 'overwhelmed', 'pressure', 'deadline', 'busy'];

    int happyScore = happyWords.where((w) => text.contains(w)).length;
    int heavyScore = heavyWords.where((w) => text.contains(w)).length;
    int lovedScore = lovedWords.where((w) => text.contains(w)).length;
    int stressedScore = stressedWords.where((w) => text.contains(w)).length;

    if (lovedScore > 0 && lovedScore >= happyScore) {
      detectedMood = "Loved ❤️";
    } else if (happyScore > heavyScore && happyScore > stressedScore) {
      detectedMood = "Happy 😊";
    } else if (heavyScore > 0) {
      detectedMood = "Heavy 💧";
    } else if (stressedScore > 0) {
      detectedMood = "Stressed 🌪️";
    }

    if (detectedMood != selectedMood) {
      setState(() {
        selectedMood = detectedMood;
        _isAnalyzingMood = true;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _isAnalyzingMood = false);
        }
      });
    }
  }

  void saveNote() {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime!).inSeconds;

    final note = NoteModel(
      title: titleCtrl.text.trim().isEmpty ? "Untitled" : titleCtrl.text.trim(),
      content: contentCtrl.text.trim(),
      createdAt: DateTime.now(),
      timeOfDay: getTimeOfDay(DateTime.now()),
      mood: selectedMood,
      writingDuration: duration,
      songs: List<NoteSong>.from(_songs),
    );

    HiveBoxes.getNotesBox().add(note);
    Navigator.pop(context);
  }

  Color _getMoodColor() {
    switch (selectedMood) {
      case "Happy 😊":
        return const Color(0xFFFBBF24); // Amber
      case "Heavy 💧":
        return const Color(0xFF3B82F6); // Blue
      case "Loved ❤️":
        return const Color(0xFFEC4899); // Pink
      case "Stressed 🌪️":
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF10B981); // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "New Note",
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.music_note, size: 20, color: Colors.white),
              ),
              onPressed: () async {
                final NoteSong? song = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SongSearchPage(),
                  ),
                );

                if (song != null) {
                  setState(() {
                    _songs.add(song);
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor,
                  _getMoodColor().withOpacity(0.05),
                  backgroundColor,
                ],
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Auto-detected mood indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getMoodColor().withOpacity(0.2),
                            _getMoodColor().withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getMoodColor().withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getMoodColor().withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isAnalyzingMood)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(_getMoodColor()),
                              ),
                            )
                          else
                            Icon(
                              Icons.auto_awesome,
                              color: _getMoodColor(),
                              size: 20,
                            ),
                          const SizedBox(width: 10),
                          Text(
                            _isAnalyzingMood ? "Detecting mood..." : "Mood: $selectedMood",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      decoration: BoxDecoration(
                        color: surfaceColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: titleCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Title",
                          hintStyle: TextStyle(
                            color: Colors.white24,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Content field
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: surfaceColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: contentCtrl,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Start writing... Your mood will be detected automatically ✨",
                            hintStyle: TextStyle(
                              color: Colors.white24,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Songs list - Instagram style
                    if (_songs.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _songs.length,
                          itemBuilder: (context, index) {
                            final song = _songs[index];

                            return TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 400 + (index * 80)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      surfaceColor.withOpacity(0.8),
                                      surfaceColor.withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Album art placeholder (Instagram style)
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            primaryColor,
                                            secondaryColor,
                                            accentColor,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                song.artist,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.6),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                                width: 3,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.4),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Text(
                                                '${song.duration}s',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.5),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 18,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _songs.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    if (_songs.isNotEmpty) const SizedBox(height: 16),

                    // Save button
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            secondaryColor,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: saveNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 24),
                            SizedBox(width: 10),
                            Text(
                              "Save Note",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}