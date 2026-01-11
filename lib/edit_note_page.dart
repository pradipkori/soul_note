import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/note_model.dart';
import 'models/note_song.dart';
import 'song_search_page.dart';
import 'services/shared_note_service.dart';

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

  final SharedNoteService _sharedService = SharedNoteService();

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.note.title);
    contentCtrl = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  // ✅ EXISTING UPDATE LOGIC (UNCHANGED)
  void updateNote() {
    widget.note.title = titleCtrl.text;
    widget.note.content = contentCtrl.text;
    widget.note.save();
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

    await widget.note.save();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note is now shared")),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          // 🤝 COLLABORATOR ICON (NEW)
          IconButton(
            icon: Icon(
              widget.note.isShared ? Icons.group : Icons.group_add,
              color: Colors.white,
            ),
            tooltip:
            widget.note.isShared ? "Shared note" : "Share note",
            onPressed: shareNote,
          ),

          // 🎵 ADD SONG (EXISTING)
          IconButton(
            icon: const Icon(Icons.music_note),
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
                widget.note.save();
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📝 TITLE
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 10),

            // 📝 CONTENT
            Expanded(
              child: TextField(
                controller: contentCtrl,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 🎵 ATTACHED SONGS (WITH DELETE BUTTON)
            if (widget.note.songs.isNotEmpty)
              Column(
                children: List.generate(
                  widget.note.songs.length,
                      (index) {
                    final song = widget.note.songs[index];

                    return Card(
                      color: Colors.white.withOpacity(0.06),
                      child: ListTile(
                        leading: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                        title: Text(
                          song.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.duration}s',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              widget.note.songs.removeAt(index);
                            });
                            widget.note.save(); // 🔥 persist deletion
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // ✅ UPDATE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateNote,
                child: const Text("Update"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
