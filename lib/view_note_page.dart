import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:soul_note/services/shared_note_service.dart';
import 'package:soul_note/services/firestore_note_service.dart';
import 'package:soul_note/services/cloud_sync_service.dart';
import 'package:soul_note/models/note_model.dart';
import 'package:soul_note/models/note_song.dart';
import 'package:soul_note/storage/hive_boxes.dart';
import 'package:soul_note/edit_note_page.dart';

class ViewNotePage extends StatefulWidget {
  final int index;

  const ViewNotePage({
    super.key,
    required this.index,
  });

  @override
  State<ViewNotePage> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  final AudioPlayer _player = AudioPlayer();
  int? _playingIndex;
  StreamSubscription? _noteSubscription;

  /// Always get latest note from Hive
  NoteModel get note =>
      HiveBoxes.getNotesBox().getAt(widget.index) as NoteModel;

  @override
  void initState() {
    super.initState();
    _setupRealtimeSync();
  }

  void _setupRealtimeSync() {
    final currentNote = note;
    if (currentNote.id.isNotEmpty) {
      debugPrint("📡 ViewNotePage: Starting real-time sync for ${currentNote.id}");
      _noteSubscription = CloudSyncService.streamNote(currentNote.id).listen((updatedNote) {
        if (updatedNote != null && mounted) {
          // Update local Hive box
          HiveBoxes.getNotesBox().putAt(widget.index, updatedNote);
          setState(() {});
          debugPrint("🔄 ViewNotePage: Note updated from cloud");
        }
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _noteSubscription?.cancel();
    super.dispose();
  }

  // Check if I can edit
  bool get canEdit {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (note.ownerId == user.uid) return true;

    // Check collaborators
    for (var collab in note.collaborators) {
      if (collab.uid == user.uid) {
        return collab.role == 'editor' || collab.role == 'owner';
      }
    }
    return false;
  }

  // 🗑 DELETE NOTE
  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await _showAnimatedConfirmDialog(
      context: context,
      title: "Delete Note?",
      message: "Are you sure you want to delete this note? This action cannot be undone.",
      confirmText: "Delete",
      confirmColor: Colors.redAccent,
      icon: Icons.delete_forever_rounded,
    );

    if (shouldDelete == true) {
      final noteId = note.id; // 1️⃣ Capture ID before local delete

      if (!context.mounted) return;
      // 2️⃣ Show overlay
      _showSyncingOverlay(context, "Deleting...");
      
      // 3️⃣ Artificial delay to keep user "busy" and let animation play
      await Future.delayed(const Duration(milliseconds: 1200));

      // 4️⃣ Delete from cloud (Firestore)
      await CloudSyncService.deleteNote(noteId);

      // 5️⃣ Perform local delete (Hive)
      HiveBoxes.getNotesBox().deleteAt(widget.index);
      
      if (!context.mounted) return;

      // 6️⃣ Dismiss overlay
      Navigator.pop(context); 
      
      if (!context.mounted) return; // Added check
      // 7️⃣ Pop ViewNotePage
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note deleted from cloud and local")),
      );
    }
  }

  // 🚪 CONFIRM LEAVE (COLLABORATOR)
  void _confirmLeave(BuildContext context) async {
    final scaffoldContext = context;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final shouldLeave = await _showAnimatedConfirmDialog(
      context: context,
      title: "Leave Note?",
      message: "You will no longer have access to this shared note.",
      confirmText: "Leave",
      confirmColor: Colors.orangeAccent,
      icon: Icons.exit_to_app_rounded,
    );

    if (shouldLeave == true) {
      if (!context.mounted) return;
      // 1️⃣ Show overlay
      _showSyncingOverlay(context, "Processing...");
      
      try {
        // 2️⃣ Perform leave (cloud action)
        await SharedNoteService().removeCollaborator(note.id, user.uid);
        
        // 3️⃣ Update local state
        HiveBoxes.getNotesBox().deleteAt(widget.index);
        
        if (!context.mounted) return;
        
        // 4️⃣ Dismiss overlay
        Navigator.pop(scaffoldContext);
        
        if (!scaffoldContext.mounted) return; // Added check
        // 5️⃣ Pop ViewNotePage
        Navigator.pop(scaffoldContext);
        
        ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
        ScaffoldMessenger.of(scaffoldContext)
            .showSnackBar(const SnackBar(content: Text("Left shared note")));
      } catch (e) {
        if (!scaffoldContext.mounted) return;
        // Dismiss overlay on error too!
        Navigator.pop(scaffoldContext);
        
        ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _showSyncingOverlay(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF151B2E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(color: Colors.white70, decoration: TextDecoration.none, fontSize: 14)),
            ],
          ),
        ).animate().scale(duration: 200.ms).fade(),
      ),
    );
  }

  Future<bool?> _showAnimatedConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: confirmColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: confirmColor, size: 32),
                      ).animate().scale(delay: 200.ms),
                      const SizedBox(height: 20),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.5)),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text("Cancel", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: confirmColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 🎵 PLAY SONG
  Future<void> _playSong(NoteSong song, int index) async {
    await _player.stop();
    setState(() => _playingIndex = index);

    await _player.play(UrlSource(song.previewUrl));
    await _player.seek(Duration(seconds: song.startSecond));

    Future.delayed(Duration(seconds: song.duration), () {
      if (!mounted) return;
      _player.stop();
      setState(() => _playingIndex = null);
    });
  }

  Future<void> _stopSong() async {
    await _player.stop();
    setState(() => _playingIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldContext = context; // ✅ SAFE CONTEXT
    final currentNote = note;
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && currentNote.ownerId == user.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          // 👥 ADD COLLABORATOR (Only for owner)
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.group_add_rounded, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (sheetContext) {
                    final emailController = TextEditingController();
                    String selectedRole = 'editor';

                    return StatefulBuilder(
                      builder: (context, setSheetState) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF151B2E).withValues(alpha: 0.8),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  offset: const Offset(0, -10),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: 12,
                              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 24),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    ).createShader(bounds),
                                    child: const Text(
                                      "Add Collaborator",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: TextField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                      decoration: InputDecoration(
                                        hintText: "Enter email address",
                                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                        border: InputBorder.none,
                                        icon: Icon(Icons.email_outlined, color: Colors.white.withValues(alpha: 0.5)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Icon(Icons.security_outlined, size: 18, color: Colors.white.withValues(alpha: 0.6)),
                                      const SizedBox(width: 8),
                                      Text(
                                        "ACCESS LEVEL",
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _modernRoleChip(
                                        label: "Viewer",
                                        icon: Icons.visibility_outlined,
                                        selected: selectedRole == 'viewer',
                                        onSelected: () => setSheetState(() => selectedRole = 'viewer'),
                                      ),
                                      const SizedBox(width: 12),
                                      _modernRoleChip(
                                        label: "Editor",
                                        icon: Icons.edit_outlined,
                                        selected: selectedRole == 'editor',
                                        onSelected: () => setSheetState(() => selectedRole = 'editor'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: () async {
                                        final email = emailController.text.trim();
                                        if (email.isEmpty) {
                                          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                            const SnackBar(content: Text("Please enter an email")),
                                          );
                                          return;
                                        }
                                        if (currentNote.id.isEmpty) return;

                                        if (currentNote.collaborators.any((c) => c.email == email)) {
                                          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                            const SnackBar(content: Text("User already has access")),
                                          );
                                          return;
                                        }

                                        Navigator.of(sheetContext).pop();
                                        _showModernProgress(scaffoldContext);

                                        try {
                                          final firestoreService = FirestoreNoteService();
                                          final exists = await firestoreService.noteExistsInFirestore(currentNote.id).timeout(
                                            const Duration(seconds: 8),
                                            onTimeout: () => throw Exception("Firestore timeout"),
                                          );

                                          if (!exists) {
                                            await firestoreService.uploadNoteToFirestore(currentNote);
                                          }

                                          await SharedNoteService().addCollaboratorByEmail(
                                            noteId: currentNote.id,
                                            collaboratorEmail: email,
                                            role: selectedRole,
                                          );

                                          currentNote.isShared = true;
                                          await HiveBoxes.getNotesBox().putAt(widget.index, currentNote);

                                           if (!context.mounted) return;
                                           ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                                           _showModernSnackBar(scaffoldContext, "✅ Collaborator added", Colors.green);
                                         } catch (e) {
                                           if (!context.mounted) return;
                                           ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                                           _showModernSnackBar(scaffoldContext, "❌ ${e.toString()}", Colors.red);
                                         }
                                      },
                                      child: const Text(
                                        "Add Collaborator",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  if (currentNote.collaborators.isNotEmpty) ...[
                                    const SizedBox(height: 32),
                                    Text(
                                      "WHO HAS ACCESS",
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 250),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: currentNote.collaborators.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                                        itemBuilder: (context, idx) {
                                          final collab = currentNote.collaborators[idx];
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.03),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                            ),
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              leading: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                                ),
                                                child: CircleAvatar(
                                                  backgroundColor: const Color(0xFF151B2E),
                                                  child: Text(
                                                    collab.email.isNotEmpty ? collab.email[0].toUpperCase() : "?",
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                              title: Text(collab.email, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                              subtitle: Text(
                                                collab.role.toUpperCase(),
                                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                              ),
                                              trailing: isOwner
                                                  ? IconButton(
                                                icon: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                                                  child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                                                ),
                                                onPressed: () async {
                                                  try {
                                                    await SharedNoteService().removeCollaborator(currentNote.id, collab.uid);
                                                    setSheetState(() => currentNote.collaborators.removeAt(idx));
                                                    await HiveBoxes.getNotesBox().putAt(widget.index, currentNote);
                                                  } catch (e) {
                                                    debugPrint("❌ Error removing collaborator: $e");
                                                  }
                                                },
                                              )
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

          // 🗑 DELETE or 🚪 LEAVE
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: () => _confirmDelete(context),
            )
          else if (currentNote.isShared)
             IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: Colors.orangeAccent),
              tooltip: "Leave shared note",
              onPressed: () => _confirmLeave(context),
            ),

          // ✏️ EDIT (Only for owner or editor)
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditNotePage(
                      note: currentNote,
                      index: widget.index,
                    ),
                  ),
                );
                setState(() {});
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
              // 📝 TITLE
              Text(
                currentNote.title.isEmpty ? "Untitled Story" : currentNote.title,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              
              // 🖋 LAST EDITED BY
              if (currentNote.lastEditedBy.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: Colors.white.withValues(alpha: 0.3), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "Last edited by ${currentNote.lastEditedBy.split('@').first}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
                  
              const SizedBox(height: 24),

              // 🌙 SOUL MOMENTS (Refined Chips)
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                   _modernMomentChip(currentNote.timeOfDay, Icons.wb_twilight_rounded),
                   _modernMomentChip(currentNote.mood, Icons.auto_awesome_rounded, color: const Color(0xFF6366F1)),
                   _modernMomentChip("${currentNote.writingDuration}s entry", Icons.timer_outlined),
                  if (currentNote.isShared)
                      _modernMomentChip("Collaborative", Icons.group_rounded, color: const Color(0xFF10B981)),
                ],
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 32),

              // 📄 CONTENT
              Text(
                currentNote.content,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 17,
                  height: 1.7,
                  letterSpacing: 0.2,
                ),
              ).animate().fadeIn(delay: 300.ms),

              // 🎵 SONGS
              if (currentNote.songs.isNotEmpty) ...[
                const SizedBox(height: 48),
                Row(
                  children: [
                    const Icon(Icons.headphones_rounded, color: Colors.white30, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "ATTACHED ATMOSPHERE",
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
                    currentNote.songs.length,
                    (index) {
                      final song = currentNote.songs[index];
                      final isPlaying = _playingIndex == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isPlaying 
                              ? const Color(0xFF6366F1).withValues(alpha: 0.1) 
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPlaying 
                                ? const Color(0xFF6366F1).withValues(alpha: 0.3) 
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: GestureDetector(
                            onTap: () => isPlaying ? _stopSong() : _playSong(song, index),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPlaying 
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: isPlaying ? const Color(0xFF6366F1) : Colors.white70,
                                size: 24,
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            "${song.artist} • ${song.duration}s preview",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                          ),
                        ),
                      ).animate().fadeIn(delay: (450 + (index * 50)).ms).slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernMomentChip(String label, IconData icon, {Color? color}) {
    final baseColor = color ?? Colors.white.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: baseColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- MODERN UI HELPERS ---

  Widget _modernRoleChip({required String label, required IconData icon, required bool selected, required VoidCallback onSelected}) {
    return Expanded(
      child: GestureDetector(
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.4), size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModernProgress(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 30),
      backgroundColor: const Color(0xFF151B2E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)))),
          const SizedBox(width: 16),
          Text("Adding collaborator...", style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    ));
  }

  void _showModernSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: color.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ));
  }
}

