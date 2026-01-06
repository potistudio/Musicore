
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import 'player_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../widgets/mini_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Request permissions as soon as the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Monochrome Music"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AudioProvider>(context, listen: false).scanSongs();
            },
          ),
        ],
      ),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          if (audioProvider.songs.isEmpty) {
            return const Center(
              child: Text(
                "No music found\nor permissions denied",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: audioProvider.songs.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey[900]),
            itemBuilder: (context, index) {
              final SongModel song = audioProvider.songs[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist ?? "Unknown Artist",
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  audioProvider.playSong(index);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlayerScreen(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(),
        ],
      ),
    );
  }
}
