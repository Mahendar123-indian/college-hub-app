import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/models/youtube_video_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  final YouTubeVideoModel video;
  final Function(Duration)? onProgressChanged;
  final VoidCallback? onVideoEnded;

  const VideoPlayerWidget({
    Key? key,
    required this.video,
    this.onProgressChanged,
    this.onVideoEnded,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _isFullScreen = false;
  PlayerState? _playerState;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
        hideControls: false,
        disableDragSeek: false,
        loop: false,
        forceHD: false,
      ),
    )..addListener(_playerListener);
  }

  void _playerListener() {
    if (_isPlayerReady && mounted) {
      final position = _controller.value.position;
      final duration = _controller.metadata.duration;

      setState(() {
        _playerState = _controller.value.playerState;
        _currentPosition = position;
        _totalDuration = duration;
      });

      // Notify parent about progress
      widget.onProgressChanged?.call(position);

      // Check if video ended
      if (_playerState == PlayerState.ended) {
        widget.onVideoEnded?.call();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // YouTube Player
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.primaryColor,
            progressColors: const ProgressBarColors(
              playedColor: AppColors.primaryColor,
              handleColor: AppColors.accentColor,
              backgroundColor: Colors.grey,
              bufferedColor: Colors.white30,
            ),
            onReady: () {
              setState(() => _isPlayerReady = true);
            },
            onEnded: (metaData) {
              widget.onVideoEnded?.call();
            },
            topActions: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            bottomActions: [
              CurrentPosition(),
              const SizedBox(width: 10),
              ProgressBar(
                isExpanded: true,
                colors: const ProgressBarColors(
                  playedColor: AppColors.primaryColor,
                  handleColor: AppColors.accentColor,
                  backgroundColor: Colors.white30,
                  bufferedColor: Colors.white24,
                ),
              ),
              const SizedBox(width: 10),
              RemainingDuration(),
              FullScreenButton(),
            ],
          ),

          // Custom Controls (if needed)
          if (_isPlayerReady) _buildCustomControls(),
        ],
      ),
    );
  }

  Widget _buildCustomControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Play/Pause Button
          IconButton(
            icon: Icon(
              _playerState == PlayerState.playing
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              if (_playerState == PlayerState.playing) {
                _controller.pause();
              } else {
                _controller.play();
              }
            },
          ),

          // Current Time
          Text(
            _formatDuration(_currentPosition),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Progress Slider
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primaryColor,
                inactiveTrackColor: Colors.white30,
                thumbColor: AppColors.accentColor,
                overlayColor: AppColors.primaryColor.withOpacity(0.3),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
              ),
              child: Slider(
                value: _currentPosition.inSeconds.toDouble(),
                min: 0,
                max: _totalDuration.inSeconds.toDouble(),
                onChanged: (value) {
                  _controller.seekTo(Duration(seconds: value.toInt()));
                },
              ),
            ),
          ),

          // Total Duration
          Text(
            _formatDuration(_totalDuration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: 8),

          // Settings Button
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 24,
            ),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Playback Speed
              ListTile(
                leading: const Icon(Icons.speed, color: AppColors.primaryColor),
                title: const Text('Playback Speed'),
                trailing: Text(
                  '${_controller.value.playbackRate}x',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                onTap: _showSpeedMenu,
              ),

              // Quality
              ListTile(
                leading: const Icon(Icons.high_quality, color: AppColors.primaryColor),
                title: const Text('Quality'),
                trailing: const Text(
                  'Auto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quality selection handled by YouTube'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // Captions
              ListTile(
                leading: const Icon(Icons.closed_caption, color: AppColors.primaryColor),
                title: const Text('Captions'),
                trailing: const Text(
                  'Auto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Caption settings handled by YouTube'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedMenu() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Playback Speed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...speeds.map((speed) {
                final isSelected = _controller.value.playbackRate == speed;
                return ListTile(
                  title: Text(
                    '${speed}x',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryColor : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primaryColor)
                      : null,
                  onTap: () {
                    _controller.setPlaybackRate(speed);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}