import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soul_note/services/collaboration_test_service.dart';
import 'package:soul_note/services/firestore_test_service.dart';
import 'models/note_model.dart';
import 'storage/hive_boxes.dart';
import 'add_note_page.dart';
import 'view_note_page.dart';
import 'services/auth_service.dart';
import 'auth/google_login_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabController.forward();

    // ✅ Fix existing notes with empty IDs
    _fixExistingNoteIds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // ✅ NEW METHOD: Fix all existing notes with empty IDs
  Future<void> _fixExistingNoteIds() async {
    final box = HiveBoxes.getNotesBox();

    for (int i = 0; i < box.length; i++) {
      final note = box.getAt(i) as NoteModel;

      if (note.id.isEmpty) {
        // Generate new unique ID
        note.id = '${DateTime.now().millisecondsSinceEpoch}_fix_${i}_${DateTime.now().microsecond}';
        await note.save();
        debugPrint('✅ Fixed note at index $i with new ID: ${note.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = HiveBoxes.getNotesBox();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'Search notes...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        )
            : const Text(
          "SoulNote",
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 36,
            color: Colors.white,
          ),
        ),
        actions: [
          // 🔍 SEARCH BUTTON
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          // ☁️ FIRESTORE TEST BUTTON
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: "Write test note to Firestore",
            onPressed: () async {
              await FirestoreTestService.writeTestNote();

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Written to Firestore'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          // 👥 TEST COLLABORATOR BUTTON
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: "Test Collaborator",
            onPressed: () async {
              try {
                const testNoteId = 'FwGzlVAbqe3IGwMs97Q6';

                await CollaborationTestService.addTestCollaborator(
                  noteId: testNoteId,
                  collaboratorEmail: 'pradipkorii2005@gmail.com',
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Collaborator added")),
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          ),
          // 🚪 LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              final authService = AuthService();
              await authService.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const GoogleLoginPage(),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<NoteModel>>(
        valueListenable: box.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No notes yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 28,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap + to add your first note.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 20,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            );
          }

          final notes = box.values.toList().cast<NoteModel>()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final filteredNotes = notes.where((note) {
            if (_searchQuery.isEmpty) return true;
            return note.title.toLowerCase().contains(_searchQuery) ||
                note.content.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filteredNotes.isEmpty && _searchQuery.isNotEmpty) {
            return const Center(
              child: Text(
                "No notes found.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 24,
                  color: Colors.white70,
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotes.length,
            itemBuilder: (context, idx) {
              final note = filteredNotes[idx];
              final noteIndex = box.values.toList().indexOf(note);

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (idx * 50)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Dismissible(
                  key: Key(note.createdAt.toString()),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade900.withOpacity(0.8),
                          Colors.red.shade600,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade900.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
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
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    box.deleteAt(noteIndex);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Note deleted"),
                        backgroundColor: Colors.grey[850],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              ViewNotePage(index: noteIndex),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;
                            var tween = Tween(begin: begin, end: end).chain(
                              CurveTween(curve: curve),
                            );
                            return SlideTransition(
                              position: animation.drive(tween),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'note_$noteIndex',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple.shade900.withOpacity(0.3),
                                Colors.deepPurple.shade700.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.deepPurple.shade300.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.shade900.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title.isEmpty ? "Untitled" : note.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                note.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(note.createdAt),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12,
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
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _fabController,
            curve: Curves.elasticOut,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade400,
                Colors.deepPurple.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.shade400.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddNotePage()),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(
              Icons.add,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return "Just now";
        }
        return "${diff.inMinutes}m ago";
      }
      return "${diff.inHours}h ago";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else if (diff.inDays < 7) {
      return "${diff.inDays}d ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}