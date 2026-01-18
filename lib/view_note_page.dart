import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Delete Note?",
              style: TextStyle(color: Colors.white)),
          content: const Text(
            "Are you sure you want to delete this note?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete",
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      HiveBoxes.getNotesBox().deleteAt(widget.index);
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note deleted")),
      );
    }
  }

  // 🚪 CONFIRM LEAVE (COLLABORATOR)
  void _confirmLeave(BuildContext context) async {
    final scaffoldContext = context;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Leave Note?", style: TextStyle(color: Colors.white)),
        content: const Text("You will no longer have access to this shared note.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Leave",
                style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      try {
        await SharedNoteService().removeCollaborator(note.id, user.uid);
        HiveBoxes.getNotesBox().deleteAt(widget.index);
        if (!mounted) return;
        Navigator.pop(scaffoldContext);
        ScaffoldMessenger.of(scaffoldContext)
            .showSnackBar(const SnackBar(content: Text("Left shared note")));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 👥 ADD COLLABORATOR (Only for owner)
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.grey[900],
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (sheetContext) {
                    final emailController = TextEditingController();
                    String selectedRole = 'editor'; // Default

                    return StatefulBuilder(
                      builder: (context, setSheetState) {
                        return Padding(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 20,
                            bottom:
                            MediaQuery.of(sheetContext).viewInsets.bottom +
                                20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Add Collaborator",
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style:
                                const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "example@gmail.com",
                                  hintStyle:
                                  const TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: Colors.black26,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 🔐 ROLE SELECTION
                              const Text("Access Level", style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text("View Only"),
                                      selected: selectedRole == 'viewer',
                                      onSelected: (val) => setSheetState(() => selectedRole = 'viewer'),
                                      selectedColor: Colors.blueGrey,
                                      labelStyle: TextStyle(color: selectedRole == 'viewer' ? Colors.white : Colors.white70),
                                      backgroundColor: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text("Full Access"),
                                      selected: selectedRole == 'editor',
                                      onSelected: (val) => setSheetState(() => selectedRole = 'editor'),
                                      selectedColor: Colors.blueGrey,
                                      labelStyle: TextStyle(color: selectedRole == 'editor' ? Colors.white : Colors.white70),
                                      backgroundColor: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  child: const Text("Add Collaborator"),
                                  onPressed: () async {
                                    final email =
                                    emailController.text.trim();

                                    if (email.isEmpty) {
                                      ScaffoldMessenger.of(
                                          scaffoldContext)
                                          .showSnackBar(const SnackBar(
                                          content: Text(
                                              "Please enter an email")));
                                      return;
                                    }

                                    if (currentNote.id.isEmpty) {
                                      ScaffoldMessenger.of(
                                          scaffoldContext)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            "Invalid note ID"),
                                        backgroundColor: Colors.red,
                                      ));
                                      return;
                                    }

                                    // Check if already exists
                                    if (currentNote.collaborators.any((c) => c.email == email)) {
                                       ScaffoldMessenger.of(scaffoldContext).showSnackBar(const SnackBar(content: Text("User already has access")));
                                       return;
                                    }

                                    Navigator.of(sheetContext).pop();

                                    ScaffoldMessenger.of(scaffoldContext)
                                        .clearSnackBars();
                                    ScaffoldMessenger.of(scaffoldContext)
                                        .showSnackBar(const SnackBar(
                                      duration: Duration(seconds: 30),
                                      content: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                            CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Text("Adding collaborator..."),
                                        ],
                                      ),
                                    ));

                                    try {
                                      final firestoreService =
                                      FirestoreNoteService();

                                      final exists = await firestoreService
                                          .noteExistsInFirestore(
                                          currentNote.id)
                                          .timeout(
                                        const Duration(seconds: 8),
                                        onTimeout: () => throw Exception(
                                            "Firestore timeout"),
                                      );

                                      if (!exists) {
                                        await firestoreService
                                            .uploadNoteToFirestore(
                                            currentNote);
                                      }

                                      await SharedNoteService()
                                          .addCollaboratorByEmail(
                                        noteId: currentNote.id,
                                        collaboratorEmail: email,
                                        role: selectedRole, // ✅ Pass the role
                                      );
                                      
                                      // ✅ Ensure local state is updated
                                      currentNote.isShared = true;
                                      await HiveBoxes.getNotesBox().putAt(widget.index, currentNote);

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(
                                          scaffoldContext)
                                          .clearSnackBars();
                                      ScaffoldMessenger.of(
                                          scaffoldContext)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            "✅ Collaborator added"),
                                        backgroundColor: Colors.green,
                                      ));
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                          scaffoldContext)
                                          .clearSnackBars();
                                      ScaffoldMessenger.of(
                                          scaffoldContext)
                                          .showSnackBar(SnackBar(
                                        content:
                                        Text("❌ ${e.toString()}"),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  },
                                ),
                              ),
                              
                              // 👥 WHO HAS ACCESS LIST
                              if (currentNote.collaborators.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Text("Who has access", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: currentNote.collaborators.length,
                                      itemBuilder: (context, idx) {
                                        final collab = currentNote.collaborators[idx];
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.deepPurple.withOpacity(0.3),
                                            child: Text(collab.email.isNotEmpty ? collab.email[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white)),
                                          ),
                                          title: Text(collab.email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                          subtitle: Text(collab.role, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                          trailing: isOwner ? IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                            onPressed: () async {
                                              try {
                                                await SharedNoteService().removeCollaborator(currentNote.id, collab.uid);
                                                setSheetState(() {
                                                  currentNote.collaborators.removeAt(idx);
                                                });
                                                await HiveBoxes.getNotesBox().putAt(widget.index, currentNote);
                                              } catch (e) {
                                                debugPrint("❌ Error removing collaborator: $e");
                                              }
                                            },
                                          ) : null,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        );
                      }
                    );
                  },
                );
              },
            ),

          // 🗑 DELETE or 🚪 LEAVE
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            )
          else if (currentNote.isShared)
             IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.orangeAccent),
              tooltip: "Leave shared note",
              onPressed: () => _confirmLeave(context),
            ),

          // ✏️ EDIT (Only for owner or editor)
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 📝 TITLE
            Text(
              currentNote.title.isEmpty
                  ? "Untitled"
                  : currentNote.title,
              style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            
            // 🖋 LAST EDITED BY
            if (currentNote.lastEditedBy.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Last edited by ${currentNote.lastEditedBy.split('@').first}",
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ),
                
            const SizedBox(height: 12),

            // 🌙 SOUL MOMENTS
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _momentChip(currentNote.timeOfDay),
                _momentChip(currentNote.mood),
                _momentChip(
                    "${currentNote.writingDuration}s writing"),
                if (currentNote.isShared)
                    _momentChip("Collaborative", color: Colors.blueGrey),
              ],
            ),
// ... rest of listview

            const SizedBox(height: 18),

            // 📄 CONTENT
            Text(
              currentNote.content,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.6),
            ),

            // 🎵 SONGS
            if (currentNote.songs.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const Text("Attached Songs",
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Column(
                children: List.generate(
                  currentNote.songs.length,
                      (index) {
                    final song = currentNote.songs[index];
                    final isPlaying =
                        _playingIndex == index;

                    return Card(
                      color: Colors.white.withOpacity(0.06),
                      child: ListTile(
                        leading: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 32,
                        ),
                        title: Text(song.title,
                            style: const TextStyle(
                                color: Colors.white)),
                        subtitle: Text(
                          "${song.artist} • ${song.duration}s",
                          style: const TextStyle(
                              color: Colors.white54),
                        ),
                        onTap: () => isPlaying
                            ? _stopSong()
                            : _playSong(song, index),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _momentChip(String label, {Color? color}) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.2) ?? Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: color?.withOpacity(0.4) ?? Colors.white.withOpacity(0.15)),
      ),
      child: Text(label,
          style:
          const TextStyle(color: Colors.white70, fontSize: 13)),
    );
  }
}
