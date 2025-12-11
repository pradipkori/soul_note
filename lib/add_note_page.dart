import 'package:flutter/material.dart';
import 'models/note_model.dart';
import 'storage/hive_boxes.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  void saveNote() {
    final note = NoteModel(
      title: titleCtrl.text.trim(),
      content: contentCtrl.text.trim(),
      createdAt: DateTime.now(),
    );
    HiveBoxes.getNotesBox().add(note);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("New Note"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: const InputDecoration(
                hintText: "Title",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: contentCtrl,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Write something...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            ElevatedButton(
              onPressed: saveNote,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
