import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:soul_note/services/shared_note_service.dart';
import 'package:soul_note/services/firestore_note_service.dart';
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

  /// Always get latest note from Hive
  NoteModel get note =>
      HiveBoxes.getNotesBox().getAt(widget.index) as NoteModel;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 👥 ADD COLLABORATOR
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
                                  currentNote.isShared = true;
                                  await currentNote.save();
                                }

                                await SharedNoteService()
                                    .addCollaboratorByEmail(
                                  noteId: currentNote.id,
                                  collaboratorEmail: email,
                                );

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
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // 🗑 DELETE
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),

          // ✏️ EDIT
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
              ],
            ),

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

  Widget _momentChip(String label) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(label,
          style:
          const TextStyle(color: Colors.white70, fontSize: 13)),
    );
  }
}
