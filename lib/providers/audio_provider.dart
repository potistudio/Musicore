import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  ConcatenatingAudioSource? _playlist;

  List<SongModel> _songs = [];
  List<SongModel> get songs => _songs;

  int? _currentIndex;
  int? get currentIndex => _currentIndex;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Duration _position = Duration.zero;
  Duration get position => _position;

  AudioProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((newDuration) {
      _duration = newDuration ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      _currentIndex = index;
      notifyListeners();
    });
  }

  Future<void> requestPermissions() async {
    // Android 13 or higher
    if (await Permission.audio.request().isGranted) {
      scanSongs();
    }
    // Android 12 or lower
    else if (await Permission.storage.request().isGranted) {
       scanSongs();
    }
  }

  Future<void> scanSongs() async {
    _songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    if (_songs.isNotEmpty) {
      _playlist = ConcatenatingAudioSource(
        children: _songs.map((song) {
          return AudioSource.uri(
            Uri.parse(song.uri!),
            tag: MediaItem(
              id: song.id.toString(),
              album: song.album ?? "Unknown Album",
              title: song.title,
              artist: song.artist ?? "Unknown Artist",
              artUri: Uri.parse("content://media/external/audio/media/${song.id}/albumart"),
            ),
          );
        }).toList(),
      );

      try {
        await _audioPlayer.setAudioSource(_playlist!);
      } catch (e) {
        debugPrint("Error setting playlist: $e");
      }
    }

    notifyListeners();
  }

  Future<void> playSong(int index) async {
    try {
      if (_songs.isEmpty) return;
      // Just seek to the correct index in the playlist
      await _audioPlayer.seek(Duration.zero, index: index);
      play();
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  void play() {
    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  // Caching
  final Map<int, List<double>> _waveformCache = {};

  List<double> getOrGenerateWaveform(int songId, Duration duration) {
    if (_waveformCache.containsKey(songId)) {
      return _waveformCache[songId]!;
    }

    // Generate pseudorandom waveform based on songId + duration
    final random = Random(songId ^ duration.inMilliseconds);
    // Limit max width to avoid crazy memory usage for hour-long mixes?
    // User requested FIXED LENGTH.
    // Let's use 1000 bars.
    int barCount = 1000;

    // Optimization: Generate simpler random
    final waveform = List<double>.filled(barCount, 0);
    for (int i = 0; i < barCount; i++) {
      waveform[i] = 0.2 + (random.nextDouble() * 0.8);
    }

    _waveformCache[songId] = waveform;
    return waveform;
  }

  void playNext() {
    if (_audioPlayer.hasNext) {
      _audioPlayer.seekToNext();
    }
  }

  void playPrevious() {
    if (_audioPlayer.hasPrevious) {
      _audioPlayer.seekToPrevious();
    }
  }
}
