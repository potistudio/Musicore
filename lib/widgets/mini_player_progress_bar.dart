import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_provider.dart';

/// A compact progress bar widget for the mini player with waveform preview on hover/press.
class MiniPlayerProgressBar extends StatefulWidget {
  const MiniPlayerProgressBar({super.key});

  @override
  State<MiniPlayerProgressBar> createState() => _MiniPlayerProgressBarState();
}

class _MiniPlayerProgressBarState extends State<MiniPlayerProgressBar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Selector<AudioProvider, ({Duration position, Duration duration, int? currentIndex})>(
      selector: (_, provider) => (
        position: provider.position,
        duration: provider.duration,
        currentIndex: provider.currentIndex,
      ),
      builder: (context, data, child) {
        final progress = data.duration.inMilliseconds > 0
            ? data.position.inMilliseconds / data.duration.inMilliseconds
            : 0.0;

        // Get waveform data for preview
        List<double> waveform = [];
        if (data.currentIndex != null && _isHovered) {
          final provider = Provider.of<AudioProvider>(context, listen: false);
          if (provider.songs.isNotEmpty && data.currentIndex! < provider.songs.length) {
            final songId = provider.songs[data.currentIndex!].id;
            waveform = provider.getOrGenerateWaveform(songId, data.duration);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            setState(() => _isHovered = true);
          },
          onTapUp: (details) {
            final provider = Provider.of<AudioProvider>(context, listen: false);
            final RenderBox box = context.findRenderObject() as RenderBox;
            final tapPosition = details.localPosition.dx / box.size.width;
            final seekPosition = Duration(
              milliseconds: (data.duration.inMilliseconds * tapPosition).round(),
            );
            provider.seek(seekPosition);
            setState(() => _isHovered = false);
          },
          onTapCancel: () {
            setState(() => _isHovered = false);
          },
          onLongPressStart: (details) {
            setState(() => _isHovered = true);
          },
          onLongPressEnd: (details) {
            final provider = Provider.of<AudioProvider>(context, listen: false);
            final RenderBox box = context.findRenderObject() as RenderBox;
            final tapPosition = details.localPosition.dx / box.size.width;
            final seekPosition = Duration(
              milliseconds: (data.duration.inMilliseconds * tapPosition.clamp(0.0, 1.0)).round(),
            );
            provider.seek(seekPosition);
            setState(() => _isHovered = false);
          },
          onLongPressMoveUpdate: (details) {
            // Could add scrubbing here if desired
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: _isHovered ? 40 : 16,
            child: Stack(
              children: [
                // Waveform preview (shown when hovering)
                if (_isHovered && waveform.isNotEmpty)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MiniWaveformPainter(
                        waveform: waveform,
                        progress: progress,
                        playedColor: Colors.white,
                        unplayedColor: Colors.grey[700]!,
                      ),
                    ),
                  ),
                // Progress bar (always shown at bottom when not hovering)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: _isHovered ? 0 : 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                      ),
                    ),
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

// Compact waveform painter for mini player preview
class _MiniWaveformPainter extends CustomPainter {
  final List<double> waveform;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  _MiniWaveformPainter({
    required this.waveform,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final paint = Paint()..strokeCap = StrokeCap.round;
    final barWidth = size.width / waveform.length;
    final progressIndex = (progress * waveform.length).floor();

    for (int i = 0; i < waveform.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final height = waveform[i] * size.height * 0.9;
      final y1 = (size.height - height) / 2;
      final y2 = (size.height + height) / 2;

      paint.color = i <= progressIndex ? playedColor : unplayedColor;
      paint.strokeWidth = (barWidth * 0.6).clamp(1.0, 3.0);

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveform != waveform;
  }
}
