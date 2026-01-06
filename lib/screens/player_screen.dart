
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_provider.dart';
import '../widgets/waveform_seek_bar.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.songs[audioProvider.currentIndex!];

    return Scaffold(
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
            // Artwork placeholder
            Container(
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
            const SizedBox(height: 40),

            // Seek Bar
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
            const SizedBox(height: 20),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: audioProvider.playPrevious,
                  icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    if (audioProvider.isPlaying) {
                      audioProvider.pause();
                    } else {
                      audioProvider.play();
                    }
                  },
                  icon: Icon(
                    audioProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: audioProvider.playNext,
                  icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
                ),
              ],
            ),
          ],
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
