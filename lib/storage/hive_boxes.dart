import 'package:hive/hive.dart';
import '../models/note_model.dart';

class HiveBoxes {
  static const String notesBox = "notesBox";

  // Helper to get the notes box
  static Box<NoteModel> getNotesBox() =>
      Hive.box<NoteModel>(notesBox);
}
