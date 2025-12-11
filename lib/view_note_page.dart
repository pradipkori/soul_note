import 'package:flutter/material.dart';
import 'edit_note_page.dart';
import 'models/note_model.dart';
import 'storage/hive_boxes.dart';

class ViewNotePage extends StatelessWidget {
  final NoteModel note;
  final int index;
  const ViewNotePage({super.key, required this.note, required this.index});

  void deleteNote(BuildContext context) {
    HiveBoxes.getNotesBox().deleteAt(index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => deleteNote(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditNotePage(note: note, index: index),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              note.title.isEmpty ? "Untitled" : note.title,
              style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(note.content, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
