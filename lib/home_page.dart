import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/note_model.dart';
import 'storage/hive_boxes.dart';
import 'add_note_page.dart';
import 'view_note_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = HiveBoxes.getNotesBox();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "SoulNote",
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 36,
            color: Colors.white,
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<NoteModel>>(
        valueListenable: box.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                "No notes yet.\nTap + to add your first note.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ),
            );
          }

          final notes = box.values.toList().cast<NoteModel>()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, idx) {
              final note = notes[idx];
              return GestureDetector(
                onTap: () {
                  final index = box.values.toList().indexOf(note);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewNotePage(note: note, index: index),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isEmpty ? "Untitled" : note.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNotePage()));
        },
        backgroundColor: Colors.deepPurple.shade300,
        child: const Icon(Icons.add),
      ),
    );
  }
}
