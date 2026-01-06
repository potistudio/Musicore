import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class WaveformSeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const WaveformSeekBar({
    super.key,
    required this.duration,
    required this.position,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends State<WaveformSeekBar> {
  final double _barWidth = 2.0;
  final double _barSpacing = 1.0;

  // Drag state
  bool _isDragging = false;
  Duration _dragPosition = Duration.zero;

  List<double> _getWaveform(BuildContext context) {
    // Helper to get waveform from provider
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (audioProvider.songs.isEmpty || audioProvider.currentIndex == null)
      return [];

    int id = audioProvider.songs[audioProvider.currentIndex!].id;
    return audioProvider.getOrGenerateWaveform(id, widget.duration);
  }

  double _calculateTotalWidth(List<double> waveform) {
    if (waveform.isEmpty) return 0;
    return waveform.length * (_barWidth + _barSpacing);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double totalWidth) {
    if (totalWidth <= 0) return;

    // Use _dragPosition instead of widget.position while dragging
    Duration currentEffectivePosition = _dragPosition;

    // Current Pixel Position
    double currentPixel =
        (currentEffectivePosition.inMilliseconds /
            widget.duration.inMilliseconds) *
        totalWidth;

    // New Pixel Position
    // Dragging RIGHT (positive delta) -> Waveform moves RIGHT -> Center stays -> Time decreases (moves left on waveform)
    double newPixel = currentPixel - details.delta.dx;

    _updateDragPositionFromPixel(newPixel, totalWidth);
  }

  void _updateDragPositionFromPixel(double pixel, double totalWidth) {
    double progress = pixel / totalWidth;
    // Clamp
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    int ms = (widget.duration.inMilliseconds * progress).round();
    Duration newPos = Duration(milliseconds: ms);

    setState(() {
      _dragPosition = newPos;
    });

    // Optional: Scrub audio while dragging?
    // If we call widget.onChanged, it might trigger the parent to seek, which updates widget.position.
    // If widget.position updates builds, does it override us?
    // We use _dragPosition in build, so update from parent is ignored for display.
    // So yes, we can scrub.
    widget.onChanged(newPos);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition = widget.position;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    // Commit the seek
    widget.onChangeEnd?.call(_dragPosition);
  }

  void _onTapUp(TapUpDetails details) {
    // Tap to seek.
    // Center is current time.
    // Tapped point is relative to center.
    // If I tap RIGHT of center (positive relative x), I want to jump FORWARD.
    // New Pixel = Current Pixel + (TapX - CenterX)

    double centerX = MediaQuery.of(context).size.width / 2;
    double offsetFromCenter = details.localPosition.dx - centerX;

    List<double> waveform = _getWaveform(context);
    double totalWidth = _calculateTotalWidth(waveform);

    // Tap is atomic, use widget.position or _dragPosition?
    // Usually widget.position as not dragging.
    double currentPixel =
        (widget.position.inMilliseconds / widget.duration.inMilliseconds) *
        totalWidth;

    double newPixel = currentPixel + offsetFromCenter;
    double progress = newPixel / totalWidth;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    int ms = (widget.duration.inMilliseconds * progress).round();
    Duration newPos = Duration(milliseconds: ms);

    widget.onChangeEnd?.call(newPos);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.songs.isEmpty || audioProvider.currentIndex == null)
          return const SizedBox();
        int id = audioProvider.songs[audioProvider.currentIndex!].id;
        List<double> waveform = audioProvider.getOrGenerateWaveform(
          id,
          widget.duration,
        );

        double totalWidth = _calculateTotalWidth(
          waveform,
        ); // Calculate here to pass to closures if needed?
        // Actually safer to recalculate inside callback to rely on validated data or pass explicitly.

        return GestureDetector(
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(d, totalWidth),
          onHorizontalDragEnd: _onHorizontalDragEnd,
          onTapUp: _onTapUp,
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: CenterLockedWaveformPainter(
                waveform: waveform,
                barWidth: _barWidth,
                barSpacing: _barSpacing,
                playedColor: Colors.white,
                unplayedColor: Colors.grey[800]!,
                // Use drag position if dragging
                currentPosition: _isDragging ? _dragPosition : widget.position,
                totalDuration: widget.duration,
                // Important: pass context/viewport width to painter if needed for optimization
              ),
            ),
          ),
        );
      },
    );
  }
}

class CenterLockedWaveformPainter extends CustomPainter {
  final List<double> waveform;
  final double barWidth;
  final double barSpacing;
  final Color playedColor;
  final Color unplayedColor;
  final Duration currentPosition;
  final Duration totalDuration;

  CenterLockedWaveformPainter({
    required this.waveform,
    required this.barWidth,
    required this.barSpacing,
    required this.playedColor,
    required this.unplayedColor,
    required this.currentPosition,
    required this.totalDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;
    final paint = Paint()..strokeCap = StrokeCap.round;

    double totalBarWidth = barWidth + barSpacing;
    double totalWidth = waveform.length * totalBarWidth;

    // Which pixel of the waveform corresponds to the current time?
    double currentPixel = 0;
    if (totalDuration.inMilliseconds > 0) {
      currentPixel =
          (currentPosition.inMilliseconds / totalDuration.inMilliseconds) *
          totalWidth;
    }

    // We want currentPixel to be drawn at size.width / 2 (Center of Canvas).
    double centerX = size.width / 2;
    // Shift: The waveform starts at X such that X + currentPixel = centerX.
    // X = centerX - currentPixel.
    double startX = centerX - currentPixel;

    // Optimization: Only iterate bars visible in Viewport [0, size.width]
    // Bar X position: startX + i * totalBarWidth
    // Visible if: 0 - barWidth <= BarX <= size.width
    // -barWidth <= startX + i*totalBarWidth <= size.width
    // -barWidth - startX <= i*totalBarWidth <= size.width - startX
    // (-barWidth - startX) / totalBarWidth <= i <= (size.width - startX) / totalBarWidth

    int firstIndex = ((-barWidth - startX) / totalBarWidth).floor();
    int lastIndex = ((size.width - startX) / totalBarWidth).ceil();

    if (firstIndex < 0) firstIndex = 0;
    if (lastIndex > waveform.length) lastIndex = waveform.length;

    for (int i = firstIndex; i < lastIndex; i++) {
      double x = startX + (i * totalBarWidth);
      double height = waveform[i] * size.height;
      if (height < 2) height = 2; // Min height

      double y1 = (size.height - height) / 2;
      double y2 = (size.height + height) / 2;

      // Determine color
      // Logic: Left of center is played?
      // "SoundCloud style": Left side is Orange (played), Right is Grey.
      // Since playhead is ALWAYS at center:
      // Bars where x < centerX are played.
      // x is left edge. center is center of specific bar?
      // Let's compare bar center.
      double barCenter = x + barWidth / 2;

      if (barCenter <= centerX) {
        paint.color = playedColor;
      } else {
        paint.color = unplayedColor;
      }

      paint.strokeWidth = barWidth;
      canvas.drawLine(
        Offset(x + barWidth / 2, y1),
        Offset(x + barWidth / 2, y2),
        paint,
      );
    }

    // Draw Center Line (Playhead)
    paint.color = Colors.redAccent;
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CenterLockedWaveformPainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition ||
        oldDelegate.waveform != waveform;
  }
}
