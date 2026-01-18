import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // For ImageFilter
import 'package:flutter_animate/flutter_animate.dart'; // For .animate() and extensions
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soul_note/models/note_model.dart';
import 'package:soul_note/models/note_song.dart';
import 'package:soul_note/song_search_page.dart';
import 'package:soul_note/services/cloud_sync_service.dart';
import 'package:soul_note/utils/mood_analyzer.dart';
import 'package:soul_note/storage/hive_boxes.dart';


class EditNotePage extends StatefulWidget {
  final NoteModel note;
  final int index;

  const EditNotePage({
    super.key,
    required this.note,
    required this.index,
  });

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late final TextEditingController titleCtrl;
  late final TextEditingController contentCtrl;

  StreamSubscription<NoteModel?>? _noteSubscription;
  Timer? _debounceTimer;
  bool _isSyncingRemote = false; // Flag to prevent feedback loops
  bool _isSaving = false; // Flag for local-to-cloud sync status
  late String selectedMood;
  bool _isAnalyzingMood = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.note.title);
    contentCtrl = TextEditingController(text: widget.note.content);
    selectedMood = widget.note.mood;

    // Listeners for local changes (Auto-save)
    titleCtrl.addListener(_onLocalChange);
    contentCtrl.addListener(_onLocalChange);
    contentCtrl.addListener(_autoDetectMood);

    // Subscribe to remote changes
    _startRemoteSync();
  }

  void _startRemoteSync() {
    _noteSubscription = CloudSyncService.streamNote(widget.note.id).listen((remoteNote) {
      if (remoteNote != null) {
        _onRemoteChange(remoteNote);
      }
    });
  }

  void _onLocalChange() {
    if (_isSyncingRemote) return;
    _debounceSave();
  }

  void _debounceSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), _autoSaveNote);
  }

  Future<void> _autoSaveNote() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';

    // Update local object
    widget.note.title = titleCtrl.text;
    widget.note.content = contentCtrl.text;
    widget.note.mood = selectedMood;
    widget.note.lastEditedBy = email;
    widget.note.lastEditedAt = DateTime.now();

    // Save to Hive
    await HiveBoxes.getNotesBox().putAt(widget.index, widget.note);

    // Push to Cloud
    try {
      await CloudSyncService.updateNote(widget.note);
    } catch (e) {
      debugPrint("❌ Auto-save cloud sync failed: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onRemoteChange(NoteModel remoteNote) {
    final user = FirebaseAuth.instance.currentUser;
    // Don't sync back our own changes
    if (remoteNote.lastEditedBy == user?.email) return;

    _isSyncingRemote = true;

    // Update Title if different
    if (titleCtrl.text != remoteNote.title) {
      _updateControllerWithCursor(titleCtrl, remoteNote.title);
    }

    // Update Content if different
    if (contentCtrl.text != remoteNote.content) {
      _updateControllerWithCursor(contentCtrl, remoteNote.content);
    }

    // Update Mood if different
    if (selectedMood != remoteNote.mood) {
      setState(() {
        selectedMood = remoteNote.mood;
      });
    }

    // Sync local widget note object
    widget.note.title = remoteNote.title;
    widget.note.content = remoteNote.content;
    widget.note.mood = remoteNote.mood;
    widget.note.lastEditedBy = remoteNote.lastEditedBy;
    widget.note.lastEditedAt = remoteNote.lastEditedAt;
    widget.note.songs = remoteNote.songs;

    _isSyncingRemote = false;
  }

  void _updateControllerWithCursor(TextEditingController controller, String newText) {
    final selection = controller.selection;

    // Apply new text
    controller.text = newText;

    // Restore selection (clamped to new text length)
    int start = selection.start;
    int end = selection.end;

    if (start > newText.length) start = newText.length;
    if (end > newText.length) end = newText.length;

    // If text was added/removed before cursor, this is a basic preservation.
    // Real OT (Operational Transformation) is complex, but this prevents jumping to end.
    controller.selection = TextSelection(
      baseOffset: start < 0 ? 0 : start,
      extentOffset: end < 0 ? 0 : end,
    );
  }

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


  @override
  void dispose() {
    _noteSubscription?.cancel();
    _debounceTimer?.cancel();
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  // ✅ EXISTING UPDATE LOGIC (UNCHANGED)
  // 🔁 UPDATE NOTE (LOCAL + CLOUD)
  Future<void> updateNote() async {
    final user = FirebaseAuth.instance.currentUser;

    // 1️⃣ Update local note
    widget.note.title = titleCtrl.text;
    widget.note.content = contentCtrl.text;
    widget.note.mood = selectedMood;
    widget.note.lastEditedBy = user?.email ?? '';
    widget.note.lastEditedAt = DateTime.now();


    await HiveBoxes.getNotesBox().putAt(widget.index, widget.note);

    // 2️⃣ Update cloud note
    try {
      await CloudSyncService.updateNote(widget.note);
    } catch (e) {
      debugPrint("❌ Cloud update failed: $e");
    }

    if (!mounted) return;

    Navigator.pop(context);
  }


  // 🤝 NEW: SHARE NOTE (COLLABORATION)
  Future<void> shareNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Already shared → do nothing
    if (widget.note.isShared) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note is already shared")),
      );
      return;
    }

    widget.note.isShared = true;
    widget.note.ownerId = user.uid;

    await HiveBoxes.getNotesBox().putAt(widget.index, widget.note);

    if (!mounted) return;
 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note is now shared")),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback
      extendBodyBehindAppBar: true, // Allow gradient to show under AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSaving
            ? const Text("Syncing...", style: TextStyle(fontSize: 14, color: Colors.white54))
            : const Text("Saved", style: TextStyle(fontSize: 14, color: Colors.white24)),
        centerTitle: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          // 🤝 COLLABORATOR ICON
          IconButton(
            icon: Icon(
              widget.note.isShared ? Icons.group_rounded : Icons.group_add_rounded,
              color: Colors.white,
            ),
            tooltip: widget.note.isShared ? "Shared note" : "Share note",
            onPressed: shareNote,
          ),

          // 🎵 ADD SONG
          IconButton(
            icon: const Icon(Icons.music_note_rounded),
            onPressed: () async {
              final NoteSong? song = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SongSearchPage(),
                ),
              );

              if (song != null) {
                setState(() {
                  widget.note.songs.add(song);
                });
                await HiveBoxes.getNotesBox().putAt(widget.index, widget.note);
                await CloudSyncService.updateNote(widget.note);
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF020617), // Slate 950
              Colors.black,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 70,
              bottom: 40,
            ),
            children: [
              // 🌙 MOOD CHIP
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                    ),
                    boxShadow: _isAnalyzingMood
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAnalyzingMood)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          ),
                        )
                      else
                        const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Text(
                        "Mood: $selectedMood",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ).animate(target: _isAnalyzingMood ? 1 : 0).shimmer(
                      duration: 1.5.seconds,
                      color: Colors.white10,
                    ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 32),

              // 📝 TITLE
              TextField(
                controller: titleCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Your Story Title',
                  hintStyle: TextStyle(color: Colors.white12, fontSize: 28),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 8),

              // 📝 CONTENT
              TextField(
                controller: contentCtrl,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 17,
                  height: 1.6,
                ),
                maxLines: null,
                minLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Start pouring your soul here...',
                  hintStyle: TextStyle(color: Colors.white10),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 32),

              // 🎵 ATTACHED SONGS
              if (widget.note.songs.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.headphones_rounded, color: Colors.white30, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "ATMOSPHERE",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                Column(
                  children: List.generate(
                    widget.note.songs.length,
                    (index) {
                      final song = widget.note.songs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.music_note_rounded, color: Color(0xFF6366F1)),
                          ),
                          title: Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${song.artist} • ${song.duration}s',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                          ),
                          trailing: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                            ),
                            onPressed: () async {
                              setState(() {
                                widget.note.songs.removeAt(index);
                              });
                              await HiveBoxes.getNotesBox().putAt(widget.index, widget.note);
                              await CloudSyncService.updateNote(widget.note);
                            },
                          ),
                        ),
                      ).animate().fadeIn(delay: (450 + (index * 50)).ms).slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // ✅ UPDATE BUTTON
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: updateNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    "SAVE CHANGES",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 16,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
