import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import 'models/note_song.dart';

class SongSearchPage extends StatefulWidget {
  const SongSearchPage({super.key});

  @override
  State<SongSearchPage> createState() => _SongSearchPageState();
}

class _SongSearchPageState extends State<SongSearchPage> {
  final TextEditingController searchCtrl = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  List<NoteSong> songs = [];
  NoteSong? selectedSong;
  bool isLoading = false;

  // 🌍 Search songs globally (iTunes)
  Future<void> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      setState(() => songs = []);
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
      "https://itunes.apple.com/search?term=$query&entity=song&limit=25",
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      final results = data["results"] as List;

      setState(() {
        songs = results
            .where((item) => item["previewUrl"] != null)
            .map(
              (item) => NoteSong(
            title: item["trackName"],
            artist: item["artistName"],
            previewUrl: item["previewUrl"],
            startSecond: 0,
            duration: 30,
          ),
        )
            .toList();
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  // ▶ Play preview
  Future<void> playSong(NoteSong song) async {
    await _player.stop();
    await _player.play(UrlSource(song.previewUrl));
  }

  // ❌ Remove selected song
  void removeSelectedSong() async {
    await _player.stop();
    setState(() {
      selectedSong = null;
    });
  }

  // ➕ Add song to note
  void addSong() {
    if (selectedSong != null) {
      Navigator.pop(context, selectedSong);
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Search Music"),
        actions: [
          if (selectedSong != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: removeSelectedSong,
            ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchCtrl,
              onChanged: searchSongs,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Search any song or artist...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          // 🎵 SONG LIST
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isSelected = selectedSong == song;

                return ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () => playSong(song),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: isSelected
                      ? IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.redAccent),
                    onPressed: removeSelectedSong,
                  )
                      : null,
                  onTap: () {
                    setState(() => selectedSong = song);
                  },
                );
              },
            ),
          ),

          // ➕ ADD BUTTON
          if (selectedSong != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: addSong,
                  child: Text("Add ${selectedSong!.title}"),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
