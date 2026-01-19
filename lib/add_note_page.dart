import 'package:flutter/material.dart';

import 'package:soul_note/models/note_model.dart';
import 'package:soul_note/models/note_song.dart';
import 'package:soul_note/storage/hive_boxes.dart';
import 'package:soul_note/utils/soul_moment_utils.dart';
import 'package:soul_note/utils/mood_analyzer.dart';

import 'package:soul_note/song_search_page.dart';
import 'package:soul_note/services/cloud_sync_service.dart';
import 'package:soul_note/widgets/drawing_canvas.dart';
import 'package:soul_note/models/drawing_stroke.dart';


class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage>
    with TickerProviderStateMixin {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();

  DateTime? startTime;
  String selectedMood = "Calm 🌿";
  bool _isAnalyzingMood = false;

  final List<NoteSong> _songs = [];
  List<DrawingStroke> _drawingStrokes = [];

  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;

  // Modern UI Colors
  final Color bg = const Color(0xFF0A0E1A);
  final Color surface = const Color(0xFF151B2E);
  final Color surfaceLight = const Color(0xFF1E2538);
  final Color primary = const Color(0xFF6366F1);
  final Color accent = const Color(0xFF8B5CF6);

  // ---------------- SAVE NOTE ----------------
  Future<void> saveNote() async {
    final duration = DateTime.now().difference(startTime!).inSeconds;

    final uniqueId =
        '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';

    final note = NoteModel(
      id: uniqueId,
      title: titleCtrl.text.trim().isNotEmpty
          ? titleCtrl.text.trim()
          : "Untitled",
      content: contentCtrl.text.trim(),
      createdAt: DateTime.now(),
      timeOfDay: getTimeOfDay(DateTime.now()),
      mood: selectedMood,
      writingDuration: duration,
      songs: List.from(_songs),
      drawingStrokes: List.from(_drawingStrokes),
    );

    // 1️⃣ SAVE LOCALLY (OFFLINE)
    await HiveBoxes.getNotesBox().add(note);

    // 2️⃣ UPLOAD TO FIRESTORE (CLOUD BACKUP)
    try {
      await CloudSyncService.uploadNote(note);
    } catch (e) {
      debugPrint("❌ Firestore upload failed: $e");
      // Do NOT block user if cloud fails
    }

    // 3️⃣ CLOSE PAGE
    if (mounted) Navigator.pop(context);
  }


  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    contentCtrl.addListener(_autoDetectMood);
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ---------------- MOOD ----------------
  void _autoDetectMood() {
    final content = contentCtrl.text;
    if (content.length < 10) return;

    final newMood = MoodAnalyzer.analyzeMood(content);

    if (newMood != selectedMood) {
      setState(() {
        _isAnalyzingMood = true;
        selectedMood = newMood;
      });

      Future.delayed(
        const Duration(milliseconds: 1000),
            () => mounted ? setState(() => _isAnalyzingMood = false) : null,
      );
    }
  }


  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [primary, accent],
          ).createShader(bounds),
          child: const Text(
            "New Note",
            style: TextStyle(
              fontFamily: "Caveat",
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.music_note_rounded, size: 22),
              onPressed: () async {
                final song = await Navigator.push<NoteSong>(
                  context,
                  MaterialPageRoute(builder: (_) => const SongSearchPage()),
                );
                if (song != null) {
                  setState(() => _songs.add(song));
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, Colors.pinkAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.brush_rounded, size: 22),
              onPressed: _showDrawingSheet,
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // Gradient Background Effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeCtrl,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  const SizedBox(height: 8),
                  _modernMoodChip(),
                  const SizedBox(height: 24),
                  _modernTitleField(),
                  const SizedBox(height: 16),
                  _modernContentField(),
                  if (_drawingStrokes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _showDrawingSheet,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: StrokePainter(strokes: _drawingStrokes),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _modernSaveButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _songs.isEmpty
          ? null
          : _FloatingSongDock(
        songs: _songs,
        onRemove: (i) => setState(() => _songs.removeAt(i)),
      ),
    );
  }

  Widget _modernMoodChip() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                surfaceLight.withValues(alpha: 0.8),
                surface.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isAnalyzingMood
                  ? primary.withValues(alpha: 0.3 + _pulseCtrl.value * 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              if (_isAnalyzingMood)
                BoxShadow(
                  color: primary.withValues(alpha: 0.2 + _pulseCtrl.value * 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isAnalyzingMood)
                Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(3),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(primary),
                  ),
                )
              else
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [primary, accent],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                "Mood: $selectedMood",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modernTitleField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            surfaceLight.withValues(alpha: 0.5),
            surface.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: titleCtrl,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        decoration: InputDecoration(
          hintText: "Title",
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _modernContentField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            surfaceLight.withValues(alpha: 0.4),
            surface.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: contentCtrl,
        maxLines: null,
        minLines: 12, // Provides a reasonable default height
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 17,
          height: 1.6,
          letterSpacing: 0.2,
        ),
        decoration: InputDecoration(
          hintText: "Start writing your thoughts...",
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 17,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _modernSaveButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.4),
            blurRadius: 20,
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
            Icon(Icons.check_circle_rounded, size: 24),
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
    );
  }

  void _showDrawingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Creative Studio",
                  style: TextStyle(
                    fontFamily: "Caveat",
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DrawingCanvas(
                initialStrokes: _drawingStrokes,
                onStrokesChanged: (newStrokes) {
                  setState(() => _drawingStrokes = newStrokes);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================================================================
/// 🔥 MODERN FLOATING SONG DOCK
/// ===================================================================
class _FloatingSongDock extends StatefulWidget {
  final List<NoteSong> songs;
  final Function(int) onRemove;

  const _FloatingSongDock({
    required this.songs,
    required this.onRemove,
  });

  @override
  State<_FloatingSongDock> createState() => _FloatingSongDockState();
}

class _FloatingSongDockState extends State<_FloatingSongDock>
    with SingleTickerProviderStateMixin {
  bool expanded = false;
  late AnimationController progressCtrl;

  @override
  void initState() {
    super.initState();
    progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: const ValueKey("song_dock"),
      direction: DismissDirection.down,
      onDismissed: (_) => setState(() => widget.songs.clear()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        height: expanded ? 180 : 96,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1E293B),
              Color(0xFF151B2E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => expanded = !expanded),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.songs.length == 1
                                      ? widget.songs[0].title
                                      : "${widget.songs.length} songs attached",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.songs.length > 1)
                                    Text(
                                      widget.songs.map((s) => s.title).join(" • "),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              ],
                            ),
                          ),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                      if (!expanded) ...[
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: progressCtrl,
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressCtrl.value,
                              minHeight: 4,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (expanded) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.songs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final s = widget.songs[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.music_note_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              onPressed: () => widget.onRemove(i),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: AnimatedBuilder(
                    animation: progressCtrl,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressCtrl.value,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}