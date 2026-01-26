import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/message_model.dart';
import '../../../../core/constants/color_constants.dart';

class VoiceMessageWidget extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const VoiceMessageWidget({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMe ? Colors.white : AppColors.primaryColor,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Waveform & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform Visualization
                SizedBox(
                  height: 32,
                  child: _buildWaveform(),
                ),

                const SizedBox(height: 4),

                // Progress & Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_getCurrentTime()),
                      style: GoogleFonts.inter(
                        color: widget.isMe
                            ? Colors.white70
                            : Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(widget.message.voiceDuration ?? 0),
                      style: GoogleFonts.inter(
                        color: widget.isMe
                            ? Colors.white70
                            : Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(25, (index) {
            final heightFactor = _isPlaying
                ? (0.3 + 0.7 * ((index + _waveformController.value * 25) % 25) / 25)
                : (0.4 + 0.6 * (index % 5) / 5);

            final isPast = _playbackProgress >= (index / 25);

            return Container(
              width: 2.5,
              height: 32 * heightFactor,
              decoration: BoxDecoration(
                color: isPast
                    ? (widget.isMe ? Colors.white : AppColors.primaryColor)
                    : (widget.isMe
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  void _togglePlayback() async {
    HapticFeedback.lightImpact();

    setState(() => _isPlaying = !_isPlaying);

    if (_isPlaying) {
      // Simulate playback
      final duration = widget.message.voiceDuration ?? 0;
      final steps = duration * 10; // 10 steps per second

      for (var i = 0; i <= steps; i++) {
        if (!_isPlaying) break;

        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          setState(() => _playbackProgress = i / steps);
        }
      }

      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackProgress = 0.0;
        });
      }
    }
  }

  int _getCurrentTime() {
    final totalDuration = widget.message.voiceDuration ?? 0;
    return (totalDuration * _playbackProgress).round();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}