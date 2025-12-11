import 'package:flutter/material.dart';
import 'models/note_model.dart';

class EditNotePage extends StatefulWidget {
  final NoteModel note;
  final int index;
  const EditNotePage({super.key, required this.note, required this.index});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late final TextEditingController titleCtrl;
  late final TextEditingController contentCtrl;

  @override
  void initState() {
    titleCtrl = TextEditingController(text: widget.note.title);
    contentCtrl = TextEditingController(text: widget.note.content);
    super.initState();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  void updateNote() {
    widget.note.title = titleCtrl.text;
    widget.note.content = contentCtrl.text;
    widget.note.save();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: contentCtrl,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                maxLines: null,
                expands: true,
              ),
            ),
            ElevatedButton(onPressed: updateNote, child: const Text("Update")),
          ],
        ),
      ),
    );
  }
}
