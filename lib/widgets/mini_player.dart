
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../screens/player_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.currentIndex == null || audioProvider.songs.isEmpty) {
          return const SizedBox.shrink();
        }

        final song = audioProvider.songs[audioProvider.currentIndex!];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          child: Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Icon / Art
                QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkHeight: 40,
                  artworkWidth: 40,
                  nullArtworkWidget: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist ?? "Unknown Artist",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Controls
                IconButton(
                  icon: Icon(
                    audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (audioProvider.isPlaying) {
                      audioProvider.pause();
                    } else {
                      audioProvider.play();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
