
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../providers/audio_provider.dart';
import '../screens/player_screen.dart';
import 'mini_player_progress_bar.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _offsetAnimation;
  double _dragOffset = 0;
  bool _hapticTriggered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      // Limit drag distance for visual feedback
      _dragOffset = _dragOffset.clamp(-40.0, 40.0);
    });

    const threshold = 25.0;
    if (!_hapticTriggered && _dragOffset.abs() >= threshold) {
      HapticFeedback.mediumImpact();
      _hapticTriggered = true;
    }
  }

  void _onDragEnd(DragEndDetails details, AudioProvider provider) {
    // Check if horizontal swipe was strong enough for track skip
    final horizontalVelocity = details.velocity.pixelsPerSecond.dx;
    if (horizontalVelocity < -300 || _dragOffset < -25) {
      provider.playNext();
    } else if (horizontalVelocity > 300 || _dragOffset > 25) {
      provider.playPrevious();
    }

    // Animate back to center with spring effect
    _offsetAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = 0;
        _hapticTriggered = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AudioProvider, SongModel?>(
      selector: (_, provider) {
        if (provider.currentIndex == null || provider.songs.isEmpty) {
          return null;
        }
        if (provider.currentIndex! >= provider.songs.length) {
          return null;
        }
        return provider.songs[provider.currentIndex!];
      },
      builder: (context, song, child) {
        if (song == null) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final offset = _animationController.isAnimating
                ? _offsetAnimation.value
                : _dragOffset;

            return Transform.translate(
              offset: Offset(offset, 0),
              child: Opacity(
                opacity: 1.0 - (offset.abs() / 200).clamp(0.0, 0.3),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                  reverseTransitionDuration: const Duration(milliseconds: 150),
                ),
              );
            },
            onPanStart: (_) {
              // Stop any running animation and reset state for new gesture
              if (_animationController.isAnimating) {
                _animationController.stop();
              }
              _dragOffset = 0;
              _hapticTriggered = false;
            },
            onPanUpdate: (details) {
              // Only handle horizontal drag for track skipping
              if (details.delta.dx.abs() > details.delta.dy.abs()) {
                _onDragUpdate(details);
              }
            },
            onPanEnd: (details) {
              final provider = Provider.of<AudioProvider>(context, listen: false);
              final velocity = details.velocity.pixelsPerSecond;

              // Check for vertical swipe up to open player (only if clearly vertical)
              if (velocity.dy < -300 && velocity.dy.abs() > velocity.dx.abs()) {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 200),
                    reverseTransitionDuration: const Duration(milliseconds: 150),
                  ),
                );
                // Reset state and don't process as horizontal swipe
                setState(() {
                  _dragOffset = 0;
                });
                return;
              }

              // Handle horizontal swipe for track skipping
              _onDragEnd(details, provider);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar with tap-to-seek and waveform preview
                const MiniPlayerProgressBar(),
                // Main content
                Container(
                  color: Colors.transparent,
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
                      Selector<AudioProvider, bool>(
                        selector: (_, provider) => provider.isPlaying,
                        builder: (context, isPlaying, child) {
                          return IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              final provider = Provider.of<AudioProvider>(context, listen: false);
                              if (isPlaying) {
                                provider.pause();
                              } else {
                                provider.play();
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
