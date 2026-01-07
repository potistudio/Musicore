
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_provider.dart';
import '../widgets/waveform_seek_bar.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe down to close player
        if (details.velocity.pixelsPerSecond.dy > 300) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Now Playing"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Static Part: Artwork, Title, Artist
            Selector<AudioProvider, SongModel>(
              selector: (context, provider) => provider.songs[provider.currentIndex!],
              builder: (context, song, child) {
                return Column(
                  children: [
                    // Artwork placeholder
                    QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkHeight: 250,
                      artworkWidth: 250,
                      artworkQuality: FilterQuality.high,
                      size: 2000,
                      quality: 100,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Song Title
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Artist Name
                    Text(
                      song.artist ?? "Unknown Artist",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),

            // Dynamic Part: Seek Bar & Time
            Consumer<AudioProvider>(
              builder: (context, audioProvider, child) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: WaveformSeekBar(
                        duration: audioProvider.duration,
                        position: audioProvider.position,
                        onChanged: (newPosition) {
                          audioProvider.seek(newPosition);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(audioProvider.position),
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          _formatDuration(audioProvider.duration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Controls
            Selector<AudioProvider, bool>(
              selector: (context, provider) => provider.isPlaying,
              builder: (context, isPlaying, child) {
                final audioProvider = Provider.of<AudioProvider>(context, listen: false);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: audioProvider.playPrevious,
                      icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        if (isPlaying) {
                          audioProvider.pause();
                        } else {
                          audioProvider.play();
                        }
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: audioProvider.playNext,
                      icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
