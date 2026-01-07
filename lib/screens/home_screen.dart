
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
      body: Selector<AudioProvider, List<SongModel>>(
        selector: (_, provider) => provider.songs,
        builder: (context, songs, child) {
          if (songs.isEmpty) {
            return const Center(
              child: Text(
                "No music found\nor permissions denied",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: songs.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey[900]),
            itemBuilder: (context, index) {
              final SongModel song = songs[index];
              return ListTile(
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
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
                  Provider.of<AudioProvider>(context, listen: false).playSong(index);
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
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            child: MiniPlayer(),
          ),
        ),
      ),
    );
  }
}
