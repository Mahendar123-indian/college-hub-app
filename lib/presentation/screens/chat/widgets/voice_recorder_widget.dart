import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/color_constants.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final int recordingSeconds;
  final VoidCallback onCancel;
  final VoidCallback onStop;

  const VoiceRecorderWidget({
    Key? key,
    required this.recordingSeconds,
    required this.onCancel,
    required this.onStop,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(top: BorderSide(color: Colors.red.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Pulsing red dot indicator
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Recording duration
            Text(
              _formatDuration(widget.recordingSeconds),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(width: 16),

            // Waveform animation (visual feedback)
            Expanded(
              child: _buildWaveform(),
            ),

            const SizedBox(width: 16),

            // Cancel button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onCancel();
              },
              tooltip: 'Cancel',
            ),

            const SizedBox(width: 8),

            // Send button
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onStop();
                },
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        20,
            (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          width: 3,
          height: _getBarHeight(index),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  double _getBarHeight(int index) {
    // Create a wave-like pattern that changes with time
    final normalizedTime = (widget.recordingSeconds % 4) / 4;
    final phase = (index / 20) * 2 * 3.14159;
    final height = 10 + (15 * (0.5 + 0.5 * (phase + normalizedTime * 2 * 3.14159)));
    return height.clamp(8.0, 25.0);
  }
}