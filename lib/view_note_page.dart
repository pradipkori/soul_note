import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'edit_note_page.dart';
import 'models/note_model.dart';
import 'models/note_song.dart';
import 'storage/hive_boxes.dart';

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

  /// 🔥 ALWAYS READ LATEST NOTE FROM HIVE
  NoteModel get note =>
      HiveBoxes.getNotesBox().getAt(widget.index)!;

  // ✅ CONFIRM DELETE (NEW)
  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "Delete Note?",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Are you sure you want to delete this note?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      HiveBoxes.getNotesBox().deleteAt(widget.index);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Note deleted"),
          backgroundColor: Colors.grey[850],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _playSong(NoteSong song, int index) async {
    await _player.stop();
    setState(() => _playingIndex = index);

    await _player.play(UrlSource(song.previewUrl));
    await _player.seek(Duration(seconds: song.startSecond));

    Future.delayed(
      Duration(seconds: song.duration),
          () {
        if (mounted) {
          _player.pause();
          setState(() => _playingIndex = null);
        }
      },
    );
  }

  Future<void> _stopSong() async {
    await _player.stop();
    setState(() => _playingIndex = null);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentNote = note;

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 🗑 DELETE (FIXED)
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
              setState(() {}); // 🔥 refresh after edit
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
                fontWeight: FontWeight.bold,
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
                  "${currentNote.writingDuration}s writing",
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 📄 CONTENT
            Text(
              currentNote.content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.6,
              ),
            ),

            // 🎵 SONGS
            if (currentNote.songs.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const Text(
                'Attached Songs',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Column(
                children: List.generate(
                  currentNote.songs.length,
                      (index) {
                    final song = currentNote.songs[index];
                    final isPlaying = _playingIndex == index;

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
                        title: Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.duration}s',
                          style: const TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                        onTap: () {
                          isPlaying
                              ? _stopSong()
                              : _playSong(song, index);
                        },
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

  // 🌙 Reusable chip
  Widget _momentChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
    );
  }
}
